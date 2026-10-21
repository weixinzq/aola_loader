// 架构角色：封装 start.swf 运行时内存桥，只通过 IPageBridge 请求整理和读取统计。
// 数据流：level/空参数 -> system.trimMemory/system.runtimeStats -> 类型化结果或分类错误。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Runtime;

internal sealed class FlashRuntimeClient
{
	private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(3);
	private readonly IPageBridge _pageBridge;

	public FlashRuntimeClient(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
	}

	public async Task<FlashTrimMemoryResult> TrimMemoryAsync(int level, CancellationToken cancellationToken)
	{
		if (level < 0 || level > 1)
		{
			throw new ArgumentOutOfRangeException(nameof(level));
		}
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("system.trimMemory", new JObject { ["level"] = level }, Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return FlashTrimMemoryResult.Failure(result.Message);
		}
		if (!(result.Value is JObject value) ||
			value.Value<string>("status") != "TrimApplied" ||
			!TryReadMemory(value, "beforeMB", out int beforeMB) ||
			!TryReadMemory(value, "afterMB", out int afterMB) ||
			!TryReadMemory(value, "privateMB", out int privateMB))
		{
			return FlashTrimMemoryResult.Failure("页面桥返回了无效的内存整理结果。");
		}
		return FlashTrimMemoryResult.Success(beforeMB, afterMB, privateMB);
	}

	public async Task<FlashRuntimeStatsResult> GetRuntimeStatsAsync(CancellationToken cancellationToken)
	{
		PageBridgeResult result = await _pageBridge.InvokeAsync(
			new PageBridgeRequest("system.runtimeStats", new JObject(), Timeout),
			cancellationToken).ConfigureAwait(false);
		if (!result.Succeeded)
		{
			return FlashRuntimeStatsResult.Failure(result.Message);
		}
		if (!(result.Value is JObject value) ||
			value.Value<string>("status") != "RuntimeStats" ||
			!TryReadMemory(value, "totalMB", out int totalMB) ||
			!TryReadMemory(value, "privateMB", out int privateMB) ||
			!TryReadMemory(value, "freeMB", out int freeMB) ||
			!TryReadMemory(value, "frameRate", out int frameRate) ||
			!TryReadQuality(value, out string quality))
		{
			return FlashRuntimeStatsResult.Failure("页面桥返回了无效的运行时统计。");
		}
		return FlashRuntimeStatsResult.Success(totalMB, privateMB, freeMB, frameRate, quality);
	}

	private static bool TryReadMemory(JObject value, string name, out int result)
	{
		result = -1;
		JToken token = value[name];
		if (token?.Type != JTokenType.Integer && token?.Type != JTokenType.Float)
		{
			return false;
		}
		double number = token.Value<double>();
		if (double.IsNaN(number) || double.IsInfinity(number) || number < 0 ||
			number > int.MaxValue || Math.Floor(number) != number)
		{
			return false;
		}
		result = (int)number;
		return true;
	}

	private static bool TryReadQuality(JObject value, out string result)
	{
		JToken token = value["quality"];
		if (token?.Type != JTokenType.String)
		{
			result = null;
			return false;
		}
		result = token.Value<string>();
		return result != null && result.Length <= 32;
	}
}

internal sealed class FlashTrimMemoryResult
{
	private FlashTrimMemoryResult(bool succeeded, int beforeMB, int afterMB, int privateMB, string message)
	{
		Succeeded = succeeded;
		BeforeMB = beforeMB;
		AfterMB = afterMB;
		PrivateMB = privateMB;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public int BeforeMB { get; }
	public int AfterMB { get; }
	public int PrivateMB { get; }
	public string Message { get; }

	public static FlashTrimMemoryResult Success(int beforeMB, int afterMB, int privateMB) =>
		new FlashTrimMemoryResult(true, beforeMB, afterMB, privateMB, null);

	public static FlashTrimMemoryResult Failure(string message) =>
		new FlashTrimMemoryResult(false, -1, -1, -1, message);
}

internal sealed class FlashRuntimeStatsResult
{
	private FlashRuntimeStatsResult(
		bool succeeded,
		int totalMB,
		int privateMB,
		int freeMB,
		int frameRate,
		string quality,
		string message)
	{
		Succeeded = succeeded;
		TotalMB = totalMB;
		PrivateMB = privateMB;
		FreeMB = freeMB;
		FrameRate = frameRate;
		Quality = quality;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }
	public int TotalMB { get; }
	public int PrivateMB { get; }
	public int FreeMB { get; }
	public int FrameRate { get; }
	public string Quality { get; }
	public string Message { get; }

	public static FlashRuntimeStatsResult Success(int totalMB, int privateMB, int freeMB, int frameRate, string quality) =>
		new FlashRuntimeStatsResult(true, totalMB, privateMB, freeMB, frameRate, quality, null);

	public static FlashRuntimeStatsResult Failure(string message) =>
		new FlashRuntimeStatsResult(false, -1, -1, -1, -1, string.Empty, message);
}
