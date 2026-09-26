// 架构角色：通过页面桥读取 Flash 战斗诊断快照与跟踪事件，并校验返回 schema。
// 数据流：诊断请求 -> IPageBridge -> BattleDiagnosticsSnapshot/trace 或分类错误。
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Diagnostics;

internal sealed class BattleDiagnosticsClient
{
	private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(3);
	private readonly IPageBridge _pageBridge;

	public BattleDiagnosticsClient(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
	}

	public async Task<BattleDiagnosticsResult> GetAsync(CancellationToken cancellationToken)
	{
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("battle.diagnostics", new JObject(), Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return BattleDiagnosticsResult.Failure(result.Message);
		}
		if (!(result.Value is JObject value) ||
			value.Value<int?>("version") != 4 ||
			!TryReadBoolean(value, "conservativeCleanupEnabled", out bool conservativeCleanupEnabled) ||
			!TryReadCount(value, "flashUptimeMs", out int flashUptimeMs) ||
			!TryReadMemory(value, "totalMemory", out long totalMemory) ||
			!TryReadMemory(value, "privateMemory", out long privateMemory) ||
			!TryReadMemory(value, "freeMemory", out long freeMemory) ||
			!TryReadCount(value, "liveFightPanels", out int liveFightPanels) ||
			!TryReadCount(value, "disposedFightPanels", out int disposedFightPanels) ||
			!TryReadCount(value, "panelCreatedCount", out int panelCreatedCount) ||
			!TryReadCount(value, "panelDisposeStartedCount", out int panelDisposeStartedCount) ||
			!TryReadCount(value, "panelDisposedCount", out int panelDisposedCount) ||
			!TryReadCount(value, "liveStartMovies", out int liveStartMovies) ||
			!TryReadCount(value, "disposedStartMovies", out int disposedStartMovies) ||
			!TryReadCount(value, "startMovieCreatedCount", out int startMovieCreatedCount) ||
			!TryReadCount(value, "startMovieDisposedCount", out int startMovieDisposedCount) ||
			!TryReadCount(value, "liveApplicationDomains", out int liveApplicationDomains) ||
			!TryReadCount(value, "releasedApplicationDomains", out int releasedApplicationDomains) ||
			!TryReadCount(value, "applicationDomainCreatedCount", out int applicationDomainCreatedCount) ||
			!TryReadCount(value, "applicationDomainReleasedCount", out int applicationDomainReleasedCount) ||
			!TryReadCount(value, "livePreloadSessions", out int livePreloadSessions) ||
			!TryReadCount(value, "activePreloadSessions", out int activePreloadSessions) ||
			!TryReadCount(value, "disposedPreloadSessions", out int disposedPreloadSessions) ||
			!TryReadCount(value, "preloadInFlightCount", out int preloadInFlightCount) ||
			!TryReadCount(value, "preloadPendingCount", out int preloadPendingCount) ||
			!TryReadCount(value, "preloadStartedCount", out int preloadStartedCount) ||
			!TryReadCount(value, "preloadCompletedCount", out int preloadCompletedCount) ||
			!TryReadCount(value, "preloadDisposedWhileLoadingCount", out int preloadDisposedWhileLoadingCount) ||
			!TryReadCount(value, "currentResourceAgeMs", out int currentResourceAgeMs) ||
			!TryReadCount(value, "liveSkillEffectLoaders", out int liveSkillEffectLoaders) ||
			!TryReadCount(value, "skillEffectRequestInFlightCount", out int skillEffectRequestInFlightCount) ||
			!TryReadCount(value, "skillEffectRequestStartedCount", out int skillEffectRequestStartedCount) ||
			!TryReadCount(value, "skillEffectRequestCompletedCount", out int skillEffectRequestCompletedCount) ||
			!TryReadCount(value, "skillEffectDisposedWhileLoadingCount", out int skillEffectDisposedWhileLoadingCount) ||
			!TryReadCount(value, "skillEffectCallbackAfterDisposeCount", out int skillEffectCallbackAfterDisposeCount) ||
			!TryReadCount(value, "activeAttackCount", out int activeAttackCount) ||
			!TryReadCount(value, "oldestAttackAgeMs", out int oldestAttackAgeMs) ||
			!TryReadCount(value, "attackMissingStrategyCount", out int attackMissingStrategyCount) ||
			!TryReadCount(value, "attackWatchdogTimeoutCount", out int attackWatchdogTimeoutCount) ||
			!TryReadCount(value, "attackRecoveryErrorCount", out int attackRecoveryErrorCount) ||
			!TryReadCount(value, "traceDroppedCount", out int traceDroppedCount) ||
			!TryReadCount(value, "stageChildren", out int stageChildren) ||
			!TryReadCount(value, "panelChildren", out int panelChildren) ||
			!TryReadNumber(value, "stageFrameRate", out double stageFrameRate) ||
			!TryReadCount(value, "frameWindowMs", out int frameWindowMs) ||
			!TryReadCount(value, "frameSampleCount", out int frameSampleCount) ||
			!TryReadCount(value, "longFrame50Count", out int longFrame50Count) ||
			!TryReadCount(value, "longFrame100Count", out int longFrame100Count) ||
			!TryReadCount(value, "longFrame200Count", out int longFrame200Count) ||
			!TryReadCount(value, "maxFrameGapMs", out int maxFrameGapMs))
		{
			return BattleDiagnosticsResult.Failure("页面桥返回了无效的战斗诊断数据。");
		}
		return BattleDiagnosticsResult.Success(new BattleDiagnosticsSnapshot(
			conservativeCleanupEnabled,
			flashUptimeMs,
			totalMemory,
			privateMemory,
			freeMemory,
			liveFightPanels,
			disposedFightPanels,
			panelCreatedCount,
			panelDisposeStartedCount,
			panelDisposedCount,
			liveStartMovies,
			disposedStartMovies,
			startMovieCreatedCount,
			startMovieDisposedCount,
			liveApplicationDomains,
			releasedApplicationDomains,
			applicationDomainCreatedCount,
			applicationDomainReleasedCount,
			livePreloadSessions,
			activePreloadSessions,
			disposedPreloadSessions,
			preloadInFlightCount,
			preloadPendingCount,
			preloadStartedCount,
			preloadCompletedCount,
			preloadDisposedWhileLoadingCount,
			currentResourceAgeMs,
			liveSkillEffectLoaders,
			skillEffectRequestInFlightCount,
			skillEffectRequestStartedCount,
			skillEffectRequestCompletedCount,
			skillEffectDisposedWhileLoadingCount,
			skillEffectCallbackAfterDisposeCount,
			activeAttackCount,
			oldestAttackAgeMs,
			attackMissingStrategyCount,
			attackWatchdogTimeoutCount,
			attackRecoveryErrorCount,
			traceDroppedCount,
			stageChildren,
			panelChildren,
			stageFrameRate,
			frameWindowMs,
			frameSampleCount,
			longFrame50Count,
			longFrame100Count,
			longFrame200Count,
			maxFrameGapMs));
	}

	public async Task<BattleTraceResult> DrainTraceEventsAsync(CancellationToken cancellationToken)
	{
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("battle.diagnostics.events", new JObject(), Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return BattleTraceResult.Failure(result.Message);
		}
		if (!(result.Value is JObject value) || value.Value<int?>("version") != 1 ||
			!TryReadCount(value, "droppedEventCount", out int droppedEventCount) ||
			!(value["events"] is JArray eventValues) || eventValues.Count > 512)
		{
			return BattleTraceResult.Failure("页面桥返回了无效的战斗资源事件。");
		}

		List<BattleTraceEvent> events = new List<BattleTraceEvent>(eventValues.Count);
		foreach (JToken token in eventValues)
		{
			if (!(token is JObject item) ||
				!TryReadCount(item, "sequence", out int sequence) || sequence < 0 ||
				!TryReadCount(item, "atMs", out int atMs) || atMs < 0 ||
				!TryReadBoundedString(item, "type", 64, false, out string type) ||
				!TryReadBoundedString(item, "resource", 512, true, out string resource) ||
				!TryReadCount(item, "durationMs", out int durationMs) ||
				!TryReadCount(item, "value", out int eventValue))
			{
				return BattleTraceResult.Failure("页面桥返回了无效的战斗资源事件。");
			}
			events.Add(new BattleTraceEvent(sequence, atMs, type, resource, durationMs, eventValue));
		}
		return BattleTraceResult.Success(events, droppedEventCount);
	}

	private static bool TryReadMemory(JObject value, string name, out long result)
	{
		result = -1;
		JToken token = value[name];
		if (token?.Type != JTokenType.Integer && token?.Type != JTokenType.Float)
		{
			return false;
		}
		double number = token.Value<double>();
		if (double.IsNaN(number) || double.IsInfinity(number) || number < -1 ||
			number > long.MaxValue || Math.Floor(number) != number)
		{
			return false;
		}
		result = (long)number;
		return true;
	}

	private static bool TryReadBoolean(JObject value, string name, out bool result)
	{
		result = false;
		JToken token = value[name];
		if (token?.Type != JTokenType.Boolean)
		{
			return false;
		}
		result = token.Value<bool>();
		return true;
	}

	private static bool TryReadCount(JObject value, string name, out int result)
	{
		result = -1;
		JToken token = value[name];
		if (token?.Type != JTokenType.Integer)
		{
			return false;
		}
		long count = token.Value<long>();
		if (count < -1 || count > int.MaxValue)
		{
			return false;
		}
		result = (int)count;
		return true;
	}

	private static bool TryReadNumber(JObject value, string name, out double result)
	{
		result = -1;
		JToken token = value[name];
		if (token?.Type != JTokenType.Integer && token?.Type != JTokenType.Float)
		{
			return false;
		}
		result = token.Value<double>();
		return !double.IsNaN(result) && !double.IsInfinity(result) && result >= -1;
	}

	private static bool TryReadBoundedString(
		JObject value,
		string name,
		int maximumLength,
		bool allowEmpty,
		out string result)
	{
		result = null;
		JToken token = value[name];
		if (token?.Type != JTokenType.String)
		{
			return false;
		}
		result = token.Value<string>();
		return result != null && result.Length <= maximumLength && (allowEmpty || result.Length > 0);
	}
}

internal sealed class BattleDiagnosticsSnapshot
{
	public BattleDiagnosticsSnapshot(
		bool conservativeCleanupEnabled,
		int flashUptimeMs,
		long totalMemory,
		long privateMemory,
		long freeMemory,
		int liveFightPanels,
		int disposedFightPanels,
		int panelCreatedCount,
		int panelDisposeStartedCount,
		int panelDisposedCount,
		int liveStartMovies,
		int disposedStartMovies,
		int startMovieCreatedCount,
		int startMovieDisposedCount,
		int liveApplicationDomains,
		int releasedApplicationDomains,
		int applicationDomainCreatedCount,
		int applicationDomainReleasedCount,
		int livePreloadSessions,
		int activePreloadSessions,
		int disposedPreloadSessions,
		int preloadInFlightCount,
		int preloadPendingCount,
		int preloadStartedCount,
		int preloadCompletedCount,
		int preloadDisposedWhileLoadingCount,
		int currentResourceAgeMs,
		int liveSkillEffectLoaders,
		int skillEffectRequestInFlightCount,
		int skillEffectRequestStartedCount,
		int skillEffectRequestCompletedCount,
		int skillEffectDisposedWhileLoadingCount,
		int skillEffectCallbackAfterDisposeCount,
		int activeAttackCount,
		int oldestAttackAgeMs,
		int attackMissingStrategyCount,
		int attackWatchdogTimeoutCount,
		int attackRecoveryErrorCount,
		int traceDroppedCount,
		int stageChildren,
		int panelChildren,
		double stageFrameRate,
		int frameWindowMs,
		int frameSampleCount,
		int longFrame50Count,
		int longFrame100Count,
		int longFrame200Count,
		int maxFrameGapMs)
	{
		ConservativeCleanupEnabled = conservativeCleanupEnabled;
		FlashUptimeMs = flashUptimeMs;
		TotalMemory = totalMemory;
		PrivateMemory = privateMemory;
		FreeMemory = freeMemory;
		LiveFightPanels = liveFightPanels;
		DisposedFightPanels = disposedFightPanels;
		PanelCreatedCount = panelCreatedCount;
		PanelDisposeStartedCount = panelDisposeStartedCount;
		PanelDisposedCount = panelDisposedCount;
		LiveStartMovies = liveStartMovies;
		DisposedStartMovies = disposedStartMovies;
		StartMovieCreatedCount = startMovieCreatedCount;
		StartMovieDisposedCount = startMovieDisposedCount;
		LiveApplicationDomains = liveApplicationDomains;
		ReleasedApplicationDomains = releasedApplicationDomains;
		ApplicationDomainCreatedCount = applicationDomainCreatedCount;
		ApplicationDomainReleasedCount = applicationDomainReleasedCount;
		LivePreloadSessions = livePreloadSessions;
		ActivePreloadSessions = activePreloadSessions;
		DisposedPreloadSessions = disposedPreloadSessions;
		PreloadInFlightCount = preloadInFlightCount;
		PreloadPendingCount = preloadPendingCount;
		PreloadStartedCount = preloadStartedCount;
		PreloadCompletedCount = preloadCompletedCount;
		PreloadDisposedWhileLoadingCount = preloadDisposedWhileLoadingCount;
		CurrentResourceAgeMs = currentResourceAgeMs;
		LiveSkillEffectLoaders = liveSkillEffectLoaders;
		SkillEffectRequestInFlightCount = skillEffectRequestInFlightCount;
		SkillEffectRequestStartedCount = skillEffectRequestStartedCount;
		SkillEffectRequestCompletedCount = skillEffectRequestCompletedCount;
		SkillEffectDisposedWhileLoadingCount = skillEffectDisposedWhileLoadingCount;
		SkillEffectCallbackAfterDisposeCount = skillEffectCallbackAfterDisposeCount;
		ActiveAttackCount = activeAttackCount;
		OldestAttackAgeMs = oldestAttackAgeMs;
		AttackMissingStrategyCount = attackMissingStrategyCount;
		AttackWatchdogTimeoutCount = attackWatchdogTimeoutCount;
		AttackRecoveryErrorCount = attackRecoveryErrorCount;
		TraceDroppedCount = traceDroppedCount;
		StageChildren = stageChildren;
		PanelChildren = panelChildren;
		StageFrameRate = stageFrameRate;
		FrameWindowMs = frameWindowMs;
		FrameSampleCount = frameSampleCount;
		LongFrame50Count = longFrame50Count;
		LongFrame100Count = longFrame100Count;
		LongFrame200Count = longFrame200Count;
		MaxFrameGapMs = maxFrameGapMs;
	}

	public bool ConservativeCleanupEnabled { get; }
	public int FlashUptimeMs { get; }
	public long TotalMemory { get; }
	public long PrivateMemory { get; }
	public long FreeMemory { get; }
	public int LiveFightPanels { get; }
	public int DisposedFightPanels { get; }
	public int PanelCreatedCount { get; }
	public int PanelDisposeStartedCount { get; }
	public int PanelDisposedCount { get; }
	public int LiveStartMovies { get; }
	public int DisposedStartMovies { get; }
	public int StartMovieCreatedCount { get; }
	public int StartMovieDisposedCount { get; }
	public int LiveApplicationDomains { get; }
	public int ReleasedApplicationDomains { get; }
	public int ApplicationDomainCreatedCount { get; }
	public int ApplicationDomainReleasedCount { get; }
	public int LivePreloadSessions { get; }
	public int ActivePreloadSessions { get; }
	public int DisposedPreloadSessions { get; }
	public int PreloadInFlightCount { get; }
	public int PreloadPendingCount { get; }
	public int PreloadStartedCount { get; }
	public int PreloadCompletedCount { get; }
	public int PreloadDisposedWhileLoadingCount { get; }
	public int CurrentResourceAgeMs { get; }
	public int LiveSkillEffectLoaders { get; }
	public int SkillEffectRequestInFlightCount { get; }
	public int SkillEffectRequestStartedCount { get; }
	public int SkillEffectRequestCompletedCount { get; }
	public int SkillEffectDisposedWhileLoadingCount { get; }
	public int SkillEffectCallbackAfterDisposeCount { get; }
	public int ActiveAttackCount { get; }
	public int OldestAttackAgeMs { get; }
	public int AttackMissingStrategyCount { get; }
	public int AttackWatchdogTimeoutCount { get; }
	public int AttackRecoveryErrorCount { get; }
	public int TraceDroppedCount { get; }
	public int StageChildren { get; }
	public int PanelChildren { get; }
	public double StageFrameRate { get; }
	public int FrameWindowMs { get; }
	public int FrameSampleCount { get; }
	public int LongFrame50Count { get; }
	public int LongFrame100Count { get; }
	public int LongFrame200Count { get; }
	public int MaxFrameGapMs { get; }
}

internal sealed class BattleTraceEvent
{
	public BattleTraceEvent(int sequence, int atMs, string type, string resource, int durationMs, int value)
	{
		Sequence = sequence;
		AtMs = atMs;
		Type = type;
		Resource = resource;
		DurationMs = durationMs;
		Value = value;
	}

	public int Sequence { get; }
	public int AtMs { get; }
	public string Type { get; }
	public string Resource { get; }
	public int DurationMs { get; }
	public int Value { get; }
}

internal sealed class BattleTraceResult
{
	private BattleTraceResult(
		bool succeeded,
		IReadOnlyList<BattleTraceEvent> events,
		int droppedEventCount,
		string message)
	{
		Succeeded = succeeded;
		Events = events ?? Array.Empty<BattleTraceEvent>();
		DroppedEventCount = droppedEventCount;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public IReadOnlyList<BattleTraceEvent> Events { get; }
	public int DroppedEventCount { get; }
	public string Message { get; }

	public static BattleTraceResult Success(IReadOnlyList<BattleTraceEvent> events, int droppedEventCount) =>
		new BattleTraceResult(true, events, droppedEventCount, null);

	public static BattleTraceResult Failure(string message) =>
		new BattleTraceResult(false, null, -1, message);
}

internal sealed class BattleDiagnosticsResult
{
	private BattleDiagnosticsResult(bool succeeded, BattleDiagnosticsSnapshot snapshot, string message)
	{
		Succeeded = succeeded;
		Snapshot = snapshot;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public BattleDiagnosticsSnapshot Snapshot { get; }
	public string Message { get; }

	public static BattleDiagnosticsResult Success(BattleDiagnosticsSnapshot snapshot) =>
		new BattleDiagnosticsResult(true, snapshot, null);

	public static BattleDiagnosticsResult Failure(string message) =>
		new BattleDiagnosticsResult(false, null, message);
}
