// 架构角色：通过页面桥调用 Flash owner probe，并严格校验返回的短 JSON。
// 数据流：mode 0..3 -> battle.probeRelease -> 类型化快照或分类错误。
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Diagnostics;

internal sealed class BattleOwnerProbeClient
{
	private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(8);
	private static readonly string[] SnapshotFields =
	{
		"totalMB",
		"privateMB",
		"titleNodes",
		"headFrameNodes",
		"signNodes",
		"displayChildren"
	};
	private static readonly string[] ActionFields =
	{
		"tipsRemoved",
		"tipsFailed",
		"tipsUnavailable",
		"headFrameCleared",
		"headFrameFailed",
		"headFrameUnavailable"
	};
	private readonly IPageBridge _pageBridge;

	public BattleOwnerProbeClient(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
	}

	public async Task<BattleOwnerProbeResult> ProbeAsync(int mode, CancellationToken cancellationToken)
	{
		if (mode < 0 || mode > 3)
		{
			throw new ArgumentOutOfRangeException(nameof(mode));
		}
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("battle.probeRelease", new JObject { ["mode"] = mode }, Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return BattleOwnerProbeResult.Failure(result.Message);
		}
		if (!(result.Value is JObject value) ||
			value.Value<int?>("version") != 1 ||
			value.Value<int?>("mode") != mode ||
			!TryReadCount(value, "startMovies", out int startMovies) ||
			!(value["before"] is JObject before) ||
			!TryReadSnapshot(before, out BattleOwnerProbeMemory beforeSnapshot) ||
			!(value["after"] is JObject after) ||
			!TryReadSnapshot(after, out BattleOwnerProbeMemory afterSnapshot) ||
			!(value["actions"] is JObject actions) ||
			!TryReadActions(actions, out BattleOwnerProbeActions actionCounts) ||
			!(value["errors"] is JArray errorValues) || errorValues.Count > 8)
		{
			return BattleOwnerProbeResult.Failure("页面桥返回了无效的 owner probe 结果。");
		}

		List<string> errors = new List<string>(errorValues.Count);
		foreach (JToken token in errorValues)
		{
			if (token?.Type != JTokenType.String)
			{
				return BattleOwnerProbeResult.Failure("页面桥返回了无效的 owner probe 错误项。");
			}
			string text = token.Value<string>();
			if (string.IsNullOrEmpty(text) || text.Length > 64)
			{
				return BattleOwnerProbeResult.Failure("页面桥返回了无效的 owner probe 错误项。");
			}
			errors.Add(text);
		}
		return BattleOwnerProbeResult.Success(new BattleOwnerProbeSnapshot(
			mode,
			startMovies,
			beforeSnapshot,
			afterSnapshot,
			actionCounts,
			errors));
	}

	private static bool TryReadSnapshot(JObject value, out BattleOwnerProbeMemory snapshot)
	{
		snapshot = null;
		foreach (string field in SnapshotFields)
		{
			if (!TryReadCount(value, field, out _))
			{
				return false;
			}
		}
		snapshot = new BattleOwnerProbeMemory(
			value.Value<int>("totalMB"),
			value.Value<int>("privateMB"),
			value.Value<int>("titleNodes"),
			value.Value<int>("headFrameNodes"),
			value.Value<int>("signNodes"),
			value.Value<int>("displayChildren"));
		return true;
	}

	private static bool TryReadActions(JObject value, out BattleOwnerProbeActions actions)
	{
		actions = null;
		foreach (string field in ActionFields)
		{
			if (!TryReadCount(value, field, out int count) || count < 0)
			{
				return false;
			}
		}
		actions = new BattleOwnerProbeActions(
			value.Value<int>("tipsRemoved"),
			value.Value<int>("tipsFailed"),
			value.Value<int>("tipsUnavailable"),
			value.Value<int>("headFrameCleared"),
			value.Value<int>("headFrameFailed"),
			value.Value<int>("headFrameUnavailable"));
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
}

internal sealed class BattleOwnerProbeMemory
{
	public BattleOwnerProbeMemory(
		int totalMB,
		int privateMB,
		int titleNodes,
		int headFrameNodes,
		int signNodes,
		int displayChildren)
	{
		TotalMB = totalMB;
		PrivateMB = privateMB;
		TitleNodes = titleNodes;
		HeadFrameNodes = headFrameNodes;
		SignNodes = signNodes;
		DisplayChildren = displayChildren;
	}

	public int TotalMB { get; }
	public int PrivateMB { get; }
	public int TitleNodes { get; }
	public int HeadFrameNodes { get; }
	public int SignNodes { get; }
	public int DisplayChildren { get; }
}

internal sealed class BattleOwnerProbeActions
{
	public BattleOwnerProbeActions(
		int tipsRemoved,
		int tipsFailed,
		int tipsUnavailable,
		int headFrameCleared,
		int headFrameFailed,
		int headFrameUnavailable)
	{
		TipsRemoved = tipsRemoved;
		TipsFailed = tipsFailed;
		TipsUnavailable = tipsUnavailable;
		HeadFrameCleared = headFrameCleared;
		HeadFrameFailed = headFrameFailed;
		HeadFrameUnavailable = headFrameUnavailable;
	}

	public int TipsRemoved { get; }
	public int TipsFailed { get; }
	public int TipsUnavailable { get; }
	public int HeadFrameCleared { get; }
	public int HeadFrameFailed { get; }
	public int HeadFrameUnavailable { get; }
}

internal sealed class BattleOwnerProbeSnapshot
{
	public BattleOwnerProbeSnapshot(
		int mode,
		int startMovies,
		BattleOwnerProbeMemory before,
		BattleOwnerProbeMemory after,
		BattleOwnerProbeActions actions,
		IReadOnlyList<string> errors)
	{
		Mode = mode;
		StartMovies = startMovies;
		Before = before;
		After = after;
		Actions = actions;
		Errors = errors ?? Array.Empty<string>();
	}

	public int Mode { get; }
	public int StartMovies { get; }
	public BattleOwnerProbeMemory Before { get; }
	public BattleOwnerProbeMemory After { get; }
	public BattleOwnerProbeActions Actions { get; }
	public IReadOnlyList<string> Errors { get; }
}

internal sealed class BattleOwnerProbeResult
{
	private BattleOwnerProbeResult(bool succeeded, BattleOwnerProbeSnapshot snapshot, string message)
	{
		Succeeded = succeeded;
		Snapshot = snapshot;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public BattleOwnerProbeSnapshot Snapshot { get; }
	public string Message { get; }

	public static BattleOwnerProbeResult Success(BattleOwnerProbeSnapshot snapshot) =>
		new BattleOwnerProbeResult(true, snapshot, null);

	public static BattleOwnerProbeResult Failure(string message) =>
		new BattleOwnerProbeResult(false, null, message);
}
