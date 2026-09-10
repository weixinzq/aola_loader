using System;
using System.Collections.Concurrent;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.Battle.State;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Diagnostics;

internal sealed class BattlePerformanceRecorder : IDisposable
{
	private static readonly TimeSpan ActiveSampleInterval = TimeSpan.FromSeconds(5);
	private static readonly TimeSpan TimerInterval = TimeSpan.FromSeconds(5);
	private static readonly TimeSpan IdleSampleInterval = TimeSpan.FromSeconds(5);
	private static readonly TimeSpan IdleSampleDuration = TimeSpan.FromSeconds(120);

	private readonly object _syncRoot = new object();
	private readonly object _writerSync = new object();
	private readonly IBattleStateSource _battleStateSource;
	private readonly BattleDiagnosticsClient _client;
	private readonly string _outputDirectory;
	private readonly ConcurrentQueue<SampleRequest> _pending = new ConcurrentQueue<SampleRequest>();
	private readonly CancellationTokenSource _cancellation = new CancellationTokenSource();
	private readonly Timer _timer;
	private StreamWriter _writer;
	private StreamWriter _traceWriter;
	private string _outputPath;
	private string _traceOutputPath;
	private AolaBattleSnapshot _lastSnapshot = new AolaBattleSnapshot();
	private DateTime _battleStartedUtc;
	private DateTime _nextActiveSampleUtc;
	private DateTime? _battleEndedUtc;
	private DateTime _lastStartPacketUtc;
	private DateTime? _nextIdleSampleUtc;
	private int _battleNumber;
	private int _workerActive;
	private bool _battleActive;
	private bool _preloadActive;
	private bool _disposed;

	public BattlePerformanceRecorder(
		IBattleStateSource battleStateSource,
		BattleDiagnosticsClient client,
		string outputDirectory)
	{
		_battleStateSource = battleStateSource ?? throw new ArgumentNullException(nameof(battleStateSource));
		_client = client ?? throw new ArgumentNullException(nameof(client));
		if (string.IsNullOrWhiteSpace(outputDirectory))
		{
			throw new ArgumentException("Performance output directory is required.", nameof(outputDirectory));
		}
		_outputDirectory = Path.GetFullPath(outputDirectory);
		_battleStateSource.SnapshotChanged += OnSnapshotChanged;
		_timer = new Timer(OnTimer, null, TimerInterval, TimerInterval);
	}

	public string OutputPath
	{
		get
		{
			lock (_writerSync)
			{
				return _outputPath;
			}
		}
	}

	public string TraceOutputPath
	{
		get
		{
			lock (_writerSync)
			{
				return _traceOutputPath;
			}
		}
	}

	private void OnSnapshotChanged(AolaBattleSnapshot snapshot)
	{
		if (snapshot == null)
		{
			return;
		}
		SampleRequest request = null;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_lastSnapshot = snapshot.Clone();
			if (string.Equals(snapshot.LastCommand, "2401", StringComparison.Ordinal) &&
				snapshot.LastUpdatedUtc != _lastStartPacketUtc)
			{
				_lastStartPacketUtc = snapshot.LastUpdatedUtc;
				_battleNumber++;
				_battleActive = true;
				_battleStartedUtc = snapshot.LastUpdatedUtc == default ? DateTime.UtcNow : snapshot.LastUpdatedUtc;
				_nextActiveSampleUtc = _battleStartedUtc + ActiveSampleInterval;
				_battleEndedUtc = null;
				_nextIdleSampleUtc = null;
				_preloadActive = false;
				request = CreateRequest("battle-start", snapshot, DateTime.UtcNow);
			}
			else if (_battleActive && snapshot.IsEnded)
			{
				_battleActive = false;
				_battleEndedUtc = snapshot.LastUpdatedUtc == default ? DateTime.UtcNow : snapshot.LastUpdatedUtc;
				_nextIdleSampleUtc = _battleEndedUtc.Value + IdleSampleInterval;
				request = CreateRequest("battle-end", snapshot, DateTime.UtcNow);
			}
		}
		if (request != null)
		{
			Enqueue(request);
		}
	}

	private void OnTimer(object state)
	{
		SampleRequest request = null;
		DateTime now = DateTime.UtcNow;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			if (_battleActive && now >= _nextActiveSampleUtc)
			{
				request = CreateRequest("battle-active", _lastSnapshot, now);
				do
				{
					_nextActiveSampleUtc += ActiveSampleInterval;
				}
				while (now >= _nextActiveSampleUtc);
			}
			else if (_battleEndedUtc.HasValue && _nextIdleSampleUtc.HasValue && now >= _nextIdleSampleUtc.Value)
			{
				TimeSpan offset = _nextIdleSampleUtc.Value - _battleEndedUtc.Value;
				request = CreateRequest("idle-" + ((int)offset.TotalSeconds).ToString(CultureInfo.InvariantCulture) + "s", _lastSnapshot, now);
				do
				{
					_nextIdleSampleUtc = _nextIdleSampleUtc.Value + IdleSampleInterval;
				}
				while (now >= _nextIdleSampleUtc.Value);
				if (_nextIdleSampleUtc.Value > _battleEndedUtc.Value + IdleSampleDuration && !_preloadActive)
				{
					_battleEndedUtc = null;
					_nextIdleSampleUtc = null;
				}
			}
		}
		if (request != null)
		{
			Enqueue(request);
		}
	}

	private SampleRequest CreateRequest(string eventName, AolaBattleSnapshot snapshot, DateTime sampleUtc)
	{
		double battleElapsed = _battleStartedUtc == default ? -1 : Math.Max(0, (sampleUtc - _battleStartedUtc).TotalSeconds);
		double idleElapsed = _battleEndedUtc.HasValue ? Math.Max(0, (sampleUtc - _battleEndedUtc.Value).TotalSeconds) : -1;
		return new SampleRequest(
			sampleUtc,
			eventName,
			_battleNumber,
			battleElapsed,
			idleElapsed,
			snapshot?.BattleUniqueId,
			snapshot?.LastCommand);
	}

	private void Enqueue(SampleRequest request)
	{
		_pending.Enqueue(request);
		StartWorker();
	}

	private void StartWorker()
	{
		if (Interlocked.CompareExchange(ref _workerActive, 1, 0) == 0)
		{
			Task.Run(ProcessPendingAsync);
		}
	}

	private async Task ProcessPendingAsync()
	{
		try
		{
			while (!_cancellation.IsCancellationRequested && _pending.TryDequeue(out SampleRequest request))
			{
				BattleDiagnosticsResult result;
				BattleTraceResult traceResult;
				DateTime observedUtc;
				try
				{
					result = await _client.GetAsync(_cancellation.Token).ConfigureAwait(false);
				}
				catch (Exception exception) when (!(exception is OperationCanceledException))
				{
					result = BattleDiagnosticsResult.Failure(exception.Message);
				}
				observedUtc = DateTime.UtcNow;
				try
				{
					traceResult = await _client.DrainTraceEventsAsync(_cancellation.Token).ConfigureAwait(false);
				}
				catch (Exception exception) when (!(exception is OperationCanceledException))
				{
					traceResult = BattleTraceResult.Failure(exception.Message);
				}
				if (!_cancellation.IsCancellationRequested)
				{
					WriteSample(request, result, traceResult, observedUtc);
				}
			}
		}
		finally
		{
			Interlocked.Exchange(ref _workerActive, 0);
			if (!_cancellation.IsCancellationRequested && !_pending.IsEmpty)
			{
				StartWorker();
			}
		}
	}

	private void WriteSample(
		SampleRequest request,
		BattleDiagnosticsResult result,
		BattleTraceResult traceResult,
		DateTime observedUtc)
	{
		lock (_syncRoot)
		{
			if (!_disposed)
			{
				BattleDiagnosticsSnapshot snapshot = result.Snapshot;
				_preloadActive = result.Succeeded && snapshot != null &&
					(snapshot.ActivePreloadSessions > 0 || snapshot.PreloadInFlightCount > 0 ||
					 snapshot.PreloadPendingCount > 0 || snapshot.SkillEffectRequestInFlightCount > 0 ||
					 snapshot.ActiveAttackCount > 0);
			}
		}
		lock (_writerSync)
		{
			if (_disposed)
			{
				return;
			}
			EnsureWriter();
			BattleDiagnosticsSnapshot snapshot = result.Snapshot;
			_writer.WriteLine(string.Join(",", new[]
			{
				Csv(request.SampleUtc.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss.fff", CultureInfo.InvariantCulture)),
				Csv(request.EventName),
				request.BattleNumber.ToString(CultureInfo.InvariantCulture),
				FormatSeconds(request.BattleElapsedSeconds),
				FormatSeconds(request.IdleElapsedSeconds),
				Csv(request.BattleUniqueId),
				Csv(request.PacketCommand),
				result.Succeeded ? "true" : "false",
				Csv(result.Message),
				snapshot?.ConservativeCleanupEnabled == true ? "true" : snapshot == null ? string.Empty : "false",
				snapshot?.FlashUptimeMs.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				FormatMemory(snapshot?.TotalMemory),
				FormatMemory(snapshot?.PrivateMemory),
				FormatMemory(snapshot?.FreeMemory),
				snapshot?.LiveFightPanels.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.DisposedFightPanels.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PanelCreatedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PanelDisposeStartedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PanelDisposedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LiveStartMovies.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.DisposedStartMovies.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.StartMovieCreatedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.StartMovieDisposedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LiveApplicationDomains.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.ReleasedApplicationDomains.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.ApplicationDomainCreatedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.ApplicationDomainReleasedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LivePreloadSessions.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.ActivePreloadSessions.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.DisposedPreloadSessions.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PreloadInFlightCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PreloadPendingCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PreloadStartedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PreloadCompletedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PreloadDisposedWhileLoadingCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.CurrentResourceAgeMs.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LiveSkillEffectLoaders.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.SkillEffectRequestInFlightCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.SkillEffectRequestStartedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.SkillEffectRequestCompletedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.SkillEffectDisposedWhileLoadingCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.SkillEffectCallbackAfterDisposeCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.ActiveAttackCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.OldestAttackAgeMs.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.AttackMissingStrategyCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.AttackWatchdogTimeoutCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.AttackRecoveryErrorCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.TraceDroppedCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.StageChildren.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.PanelChildren.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				FormatNumber(snapshot?.StageFrameRate),
				snapshot?.FrameWindowMs.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.FrameSampleCount.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LongFrame50Count.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LongFrame100Count.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.LongFrame200Count.ToString(CultureInfo.InvariantCulture) ?? string.Empty,
				snapshot?.MaxFrameGapMs.ToString(CultureInfo.InvariantCulture) ?? string.Empty
			}));
			_writer.Flush();
			WriteTraceEvents(request, result.Snapshot, traceResult, observedUtc);
		}
	}

	private void WriteTraceEvents(
		SampleRequest request,
		BattleDiagnosticsSnapshot snapshot,
		BattleTraceResult result,
		DateTime observedUtc)
	{
		if (!result.Succeeded)
		{
			_traceWriter.WriteLine(new JObject
			{
				["recordType"] = "read-error",
				["timeUtc"] = observedUtc.ToString("O", CultureInfo.InvariantCulture),
				["sampleEvent"] = request.EventName,
				["battleNumber"] = request.BattleNumber,
				["message"] = result.Message
			}.ToString(Formatting.None));
			_traceWriter.Flush();
			return;
		}

		foreach (BattleTraceEvent item in result.Events)
		{
			DateTime eventUtc = snapshot == null
				? observedUtc
				: observedUtc.AddMilliseconds(item.AtMs - snapshot.FlashUptimeMs);
			_traceWriter.WriteLine(new JObject
			{
				["recordType"] = "flash-event",
				["timeUtc"] = eventUtc.ToString("O", CultureInfo.InvariantCulture),
				["observedUtc"] = observedUtc.ToString("O", CultureInfo.InvariantCulture),
				["sampleEvent"] = request.EventName,
				["battleNumber"] = request.BattleNumber,
				["sequence"] = item.Sequence,
				["flashAtMs"] = item.AtMs,
				["type"] = item.Type,
				["resource"] = item.Resource,
				["durationMs"] = item.DurationMs,
				["value"] = item.Value,
				["droppedEventCount"] = result.DroppedEventCount
			}.ToString(Formatting.None));
		}
		_traceWriter.Flush();
	}

	private void EnsureWriter()
	{
		if (_writer != null)
		{
			return;
		}
		Directory.CreateDirectory(_outputDirectory);
		_outputPath = Path.Combine(
			_outputDirectory,
			"aola-battle-flash-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-fff", CultureInfo.InvariantCulture) + ".csv");
		string traceStem = Path.GetFileNameWithoutExtension(_outputPath).Replace("aola-battle-flash-", "aola-battle-resource-");
		_traceOutputPath = Path.Combine(_outputDirectory, traceStem + ".jsonl");
		_writer = new StreamWriter(
			new FileStream(_outputPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read),
			new UTF8Encoding(false));
		_traceWriter = new StreamWriter(
			new FileStream(_traceOutputPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read),
			new UTF8Encoding(false));
		_writer.WriteLine("Time,Event,BattleNumber,BattleElapsedSeconds,IdleElapsedSeconds,PacketBattleUniqueId,PacketCommand,BridgeAvailable,BridgeMessage,ConservativeCleanupEnabled,FlashUptimeMs,FlashTotalMemoryMB,FlashPrivateMemoryMB,FlashFreeMemoryMB,LiveFightPanels,DisposedFightPanels,PanelCreatedCount,PanelDisposeStartedCount,PanelDisposedCount,LiveStartMovies,DisposedStartMovies,StartMovieCreatedCount,StartMovieDisposedCount,LiveApplicationDomains,ReleasedApplicationDomains,ApplicationDomainCreatedCount,ApplicationDomainReleasedCount,LivePreloadSessions,ActivePreloadSessions,DisposedPreloadSessions,PreloadInFlightCount,PreloadPendingCount,PreloadStartedCount,PreloadCompletedCount,PreloadDisposedWhileLoadingCount,CurrentResourceAgeMs,LiveSkillEffectLoaders,SkillEffectRequestInFlightCount,SkillEffectRequestStartedCount,SkillEffectRequestCompletedCount,SkillEffectDisposedWhileLoadingCount,SkillEffectCallbackAfterDisposeCount,ActiveAttackCount,OldestAttackAgeMs,AttackMissingStrategyCount,AttackWatchdogTimeoutCount,AttackRecoveryErrorCount,TraceDroppedCount,StageChildren,PanelChildren,StageFrameRate,FrameWindowMs,FrameSampleCount,LongFrame50Count,LongFrame100Count,LongFrame200Count,MaxFrameGapMs");
		_writer.Flush();
	}

	private static string FormatSeconds(double seconds) =>
		seconds < 0 ? string.Empty : seconds.ToString("0.000", CultureInfo.InvariantCulture);

	private static string FormatMemory(long? bytes) =>
		!bytes.HasValue || bytes.Value < 0
			? string.Empty
			: (bytes.Value / 1048576d).ToString("0.000", CultureInfo.InvariantCulture);

	private static string FormatNumber(double? value) =>
		!value.HasValue || value.Value < 0
			? string.Empty
			: value.Value.ToString("0.###", CultureInfo.InvariantCulture);

	private static string Csv(string value)
	{
		string text = value ?? string.Empty;
		return "\"" + text.Replace("\"", "\"\"") + "\"";
	}

	public void Dispose()
	{
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			_battleStateSource.SnapshotChanged -= OnSnapshotChanged;
		}
		_timer.Dispose();
		_cancellation.Cancel();
		lock (_writerSync)
		{
			_writer?.Dispose();
			_writer = null;
			_traceWriter?.Dispose();
			_traceWriter = null;
		}
	}

	private sealed class SampleRequest
	{
		public SampleRequest(
			DateTime sampleUtc,
			string eventName,
			int battleNumber,
			double battleElapsedSeconds,
			double idleElapsedSeconds,
			string battleUniqueId,
			string packetCommand)
		{
			SampleUtc = sampleUtc;
			EventName = eventName;
			BattleNumber = battleNumber;
			BattleElapsedSeconds = battleElapsedSeconds;
			IdleElapsedSeconds = idleElapsedSeconds;
			BattleUniqueId = battleUniqueId ?? string.Empty;
			PacketCommand = packetCommand ?? string.Empty;
		}

		public DateTime SampleUtc { get; }
		public string EventName { get; }
		public int BattleNumber { get; }
		public double BattleElapsedSeconds { get; }
		public double IdleElapsedSeconds { get; }
		public string BattleUniqueId { get; }
		public string PacketCommand { get; }
	}
}
