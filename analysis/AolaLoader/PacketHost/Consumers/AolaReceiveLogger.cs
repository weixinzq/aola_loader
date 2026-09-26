// 架构角色：按用户请求订阅并保留收发 packet 为脱敏 JSONL，默认不落盘。
// 数据流：IAolaPacketEventSource -> 序列化/短暂缓冲 -> logs/aola-recv-*.jsonl。
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security;
using System.Text;
using AolaLoader.PacketHost;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.PacketHost.Consumers;

internal sealed class AolaReceiveLogger : IDisposable
{
	private const int MaximumBufferedBytes = 8 * 1024 * 1024;
	private readonly object _syncRoot = new object();
	private readonly IAolaPacketEventSource _packetEventSource;
	private readonly string _baseDirectory;
	private Queue<string> _pendingLines = new Queue<string>();
	private StreamWriter _writer;
	private int _pendingBytes;
	private long _discardedRecordCount;
	private bool _disposed;
	private bool _retaining;
	private bool _writeFailureReported;

	public AolaReceiveLogger(IAolaPacketEventSource packetEventSource)
		: this(packetEventSource, AppDomain.CurrentDomain.BaseDirectory)
	{
	}

	internal AolaReceiveLogger(IAolaPacketEventSource packetEventSource, string baseDirectory)
	{
		_packetEventSource = packetEventSource ??
			throw new ArgumentNullException(nameof(packetEventSource));
		if (string.IsNullOrWhiteSpace(baseDirectory))
		{
			throw new ArgumentException("日志基础目录不能为空", nameof(baseDirectory));
		}
		_baseDirectory = baseDirectory;
		// 事件始终订阅，但 TryRetain 前 _writer 为空且 _retaining=false，收到的包不会落盘。
		_packetEventSource.PacketReceived += OnPacketReceived;
	}

	public string LogPath { get; private set; }

	public string ErrorMessage { get; private set; }

	public bool IsActive
	{
		get
		{
			lock (_syncRoot)
			{
				return !_disposed;
			}
		}
	}

	public bool IsRetained
	{
		get
		{
			lock (_syncRoot)
			{
				return !_disposed && _writer != null;
			}
		}
	}

	public long DiscardedRecordCount
	{
		get
		{
			lock (_syncRoot)
			{
				return _discardedRecordCount;
			}
		}
	}

	public bool TryRetain(out string logPath, out string errorMessage)
	{
		List<string> drainedLines = new List<string>();
		string[] batch;
		lock (_syncRoot)
		{
			logPath = LogPath;
			errorMessage = null;
			if (_disposed)
			{
				errorMessage = "收发日志记录器已经关闭。";
				return false;
			}
			if (_writer != null)
			{
				return true;
			}
			if (_retaining)
			{
				errorMessage = "收发日志正在保留，请稍候。";
				return false;
			}
			// 标记转换窗口，使打开文件期间到达的 packet 进入 _pendingLines，而不是丢失。
			_retaining = true;
			batch = DrainPendingLines();
			drainedLines.AddRange(batch);
		}

		StreamWriter writer = null;
		try
		{
			string directory = Path.Combine(_baseDirectory, "logs");
			Directory.CreateDirectory(directory);
			string path = CreateUniqueLogPath(directory);
			FileStream stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.ReadWrite);
			writer = new StreamWriter(stream, new UTF8Encoding(false));
			while (true)
			{
				foreach (string line in batch)
				{
					writer.WriteLine(line);
				}
				writer.Flush();
				lock (_syncRoot)
				{
					if (_disposed)
					{
						_retaining = false;
						writer.Dispose();
						errorMessage = "收发日志记录器已经关闭。";
						return false;
					}
					if (_pendingLines.Count == 0)
					{
						writer.AutoFlush = true;
						_writer = writer;
						LogPath = path;
						ErrorMessage = null;
						_writeFailureReported = false;
						_retaining = false;
						logPath = path;
						return true;
					}
					batch = DrainPendingLines();
					drainedLines.AddRange(batch);
				}
			}
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException || ex is SecurityException)
		{
			writer?.Dispose();
			lock (_syncRoot)
			{
				RestoreDrainedLines(drainedLines);
				_retaining = false;
				ErrorMessage = ex.Message;
			}
			errorMessage = ex.Message;
			return false;
		}
	}

	private string[] DrainPendingLines()
	{
		string[] lines = _pendingLines.ToArray();
		_pendingLines.Clear();
		_pendingBytes = 0;
		return lines;
	}

	private void RestoreDrainedLines(IEnumerable<string> drainedLines)
	{
		Queue<string> newerLines = _pendingLines;
		_pendingLines = new Queue<string>();
		_pendingBytes = 0;
		foreach (string line in drainedLines)
		{
			BufferLine(line);
		}
		foreach (string line in newerLines)
		{
			BufferLine(line);
		}
	}

	private static string CreateUniqueLogPath(string directory)
	{
		string stem = "aola-recv-" + DateTime.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture);
		string path = Path.Combine(directory, stem + ".jsonl");
		for (int suffix = 1; File.Exists(path); suffix++)
		{
			path = Path.Combine(directory, stem + "-" + suffix.ToString(CultureInfo.InvariantCulture) + ".jsonl");
		}
		return path;
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		if (packet == null ||
			!string.Equals(packet.Direction, "接收", StringComparison.Ordinal) &&
			!string.Equals(packet.Direction, "发送", StringComparison.Ordinal))
		{
			return;
		}
		lock (_syncRoot)
		{
			// 默认关闭时直接忽略；pending queue 只桥接“正在开启保留”的短暂窗口，不回放历史包。
			if (_disposed || _writer == null && !_retaining)
			{
				return;
			}
		}

		string line;
		try
		{
			line = CreateRecord(packet).ToString(Formatting.None);
		}
		catch (Exception ex) when (ex is JsonException || ex is FormatException || ex is InvalidOperationException)
		{
			bool redactLogin = IsLoginPacket(packet);
			line = new JObject
			{
				["timeUtc"] = packet.TimestampUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
				["direction"] = packet.Direction,
				["decoded"] = false,
				["logError"] = ex.Message,
				["rawHex"] = redactLogin ? "<登录帧已脱敏>" : packet.RawHex ?? string.Empty
			}.ToString(Formatting.None);
		}

		string writeError = null;
		bool reportWriteFailure = false;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			if (_writer == null)
			{
				BufferLine(line);
				return;
			}
			try
			{
				_writer.WriteLine(line);
			}
			catch (Exception ex) when (ex is IOException || ex is ObjectDisposedException)
			{
				writeError = ex.Message;
				ErrorMessage = ex.Message;
				_writer.Dispose();
				_writer = null;
				BufferLine(line);
				if (!_writeFailureReported)
				{
					_writeFailureReported = true;
					reportWriteFailure = true;
				}
			}
		}

		if (writeError != null && reportWriteFailure)
		{
			AolaHookHostService.ReportLocal(new AolaHookStatus
			{
				TimestampUtc = DateTime.UtcNow,
				Level = "ERROR",
				Message = "收发日志写入失败：" + writeError
			});
		}
	}

	private void BufferLine(string line)
	{
		int lineBytes = Encoding.UTF8.GetByteCount(line) + 1;
		if (lineBytes > MaximumBufferedBytes)
		{
			_discardedRecordCount++;
			return;
		}
		while (_pendingLines.Count > 0 && _pendingBytes + lineBytes > MaximumBufferedBytes)
		{
			string discarded = _pendingLines.Dequeue();
			_pendingBytes -= Encoding.UTF8.GetByteCount(discarded) + 1;
			_discardedRecordCount++;
		}
		_pendingLines.Enqueue(line);
		_pendingBytes += lineBytes;
	}

	private static JObject CreateRecord(AolaPacketEvent packet)
	{
		bool redactLogin = IsLoginPacket(packet);
		JObject record = new JObject
		{
			["timeUtc"] = packet.TimestampUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
			["timeLocal"] = packet.TimestampUtc.ToLocalTime().ToString("O", CultureInfo.InvariantCulture),
			["direction"] = packet.Direction,
			["processId"] = packet.ProcessId,
			["socket"] = packet.SocketHandle,
			["connectionPlayerId"] = packet.ConnectionPlayerId,
			["length"] = packet.FrameLength,
			["decoded"] = packet.DecodeSucceeded
		};
		AddValue(record, "outerSeq", packet.OuterSequence);
		AddValue(record, "type", packet.MessageType);
		AddValue(record, "action", packet.Action);
		AddValue(record, "extensionId", packet.ExtensionId);
		AddText(record, "cmd", packet.Command);
		AddText(record, "summary", packet.Summary);

		if (!redactLogin && !string.IsNullOrWhiteSpace(packet.ParametersJson))
		{
			try
			{
				record["param"] = JToken.Parse(packet.ParametersJson);
			}
			catch (JsonException)
			{
				record["paramText"] = packet.ParametersJson;
			}
		}
		if (!redactLogin)
		{
			AddText(record, "innerPlainHex", packet.InnerPlainHex);
			AddText(record, "rawHex", packet.RawHex);
		}
		else
		{
			record["rawHex"] = "<登录帧已脱敏>";
		}
		return record;
	}

	private static bool IsLoginPacket(AolaPacketEvent packet)
	{
		return string.Equals(packet.Direction, "发送", StringComparison.Ordinal) &&
			(packet.Action == 10016 || string.Equals(packet.Command, "logIn", StringComparison.Ordinal));
	}

	private static void AddValue(JObject record, string name, long? value)
	{
		if (value.HasValue)
		{
			record[name] = value.Value;
		}
	}

	private static void AddValue(JObject record, string name, int? value)
	{
		if (value.HasValue)
		{
			record[name] = value.Value;
		}
	}

	private static void AddText(JObject record, string name, string value)
	{
		if (!string.IsNullOrWhiteSpace(value))
		{
			record[name] = value;
		}
	}

	public void Dispose()
	{
		_packetEventSource.PacketReceived -= OnPacketReceived;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			_writer?.Dispose();
			_writer = null;
			_pendingLines.Clear();
			_pendingBytes = 0;
		}
	}
}
