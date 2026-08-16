using System;
using System.Globalization;
using System.IO;
using System.Security;
using System.Text;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader;

internal sealed class AolaReceiveLogger : IDisposable
{
	private readonly object _syncRoot = new object();
	private StreamWriter _writer;
	private bool _disposed;
	private bool _writeFailureReported;

	public AolaReceiveLogger()
		: this(AppDomain.CurrentDomain.BaseDirectory)
	{
	}

	internal AolaReceiveLogger(string baseDirectory)
	{
		try
		{
			if (string.IsNullOrWhiteSpace(baseDirectory))
			{
				throw new ArgumentException("日志基础目录不能为空", nameof(baseDirectory));
			}
			string directory = Path.Combine(baseDirectory, "logs");
			Directory.CreateDirectory(directory);
			LogPath = Path.Combine(directory, "aola-recv-" + DateTime.Now.ToString("yyyyMMdd-HHmmss", CultureInfo.InvariantCulture) + ".jsonl");
			FileStream stream = new FileStream(LogPath, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
			_writer = new StreamWriter(stream, new UTF8Encoding(false)) { AutoFlush = true };
			AolaHookHostService.PacketReceived += OnPacketReceived;
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException || ex is SecurityException)
		{
			ErrorMessage = ex.Message;
		}
	}

	public string LogPath { get; }

	public string ErrorMessage { get; private set; }

	public bool IsActive
	{
		get
		{
			lock (_syncRoot)
			{
				return !_disposed && _writer != null;
			}
		}
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		if (packet == null || !string.Equals(packet.Direction, "接收", StringComparison.Ordinal))
		{
			return;
		}

		string line;
		try
		{
			line = CreateRecord(packet).ToString(Formatting.None);
		}
		catch (Exception ex) when (ex is JsonException || ex is FormatException || ex is InvalidOperationException)
		{
			line = new JObject
			{
				["timeUtc"] = packet.TimestampUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
				["direction"] = "接收",
				["decoded"] = false,
				["logError"] = ex.Message,
				["rawHex"] = packet.RawHex ?? string.Empty
			}.ToString(Formatting.None);
		}

		string writeError = null;
		lock (_syncRoot)
		{
			if (_disposed || _writer == null)
			{
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
			}
		}

		if (writeError != null && !_writeFailureReported)
		{
			_writeFailureReported = true;
			AolaHookHostService.ReportLocal(new AolaHookStatus
			{
				TimestampUtc = DateTime.UtcNow,
				Level = "ERROR",
				Message = "接收日志写入失败：" + writeError
			});
		}
	}

	private static JObject CreateRecord(AolaPacketEvent packet)
	{
		JObject record = new JObject
		{
			["timeUtc"] = packet.TimestampUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
			["timeLocal"] = packet.TimestampUtc.ToLocalTime().ToString("O", CultureInfo.InvariantCulture),
			["direction"] = packet.Direction,
			["processId"] = packet.ProcessId,
			["socket"] = packet.SocketHandle,
			["length"] = packet.FrameLength,
			["decoded"] = packet.DecodeSucceeded
		};
		AddValue(record, "outerSeq", packet.OuterSequence);
		AddValue(record, "type", packet.MessageType);
		AddValue(record, "action", packet.Action);
		AddValue(record, "extensionId", packet.ExtensionId);
		AddText(record, "cmd", packet.Command);
		AddText(record, "summary", packet.Summary);

		if (!string.IsNullOrWhiteSpace(packet.ParametersJson))
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
		AddText(record, "innerPlainHex", packet.InnerPlainHex);
		AddText(record, "rawHex", packet.RawHex);
		return record;
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
		AolaHookHostService.PacketReceived -= OnPacketReceived;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			_writer?.Dispose();
			_writer = null;
		}
	}
}
