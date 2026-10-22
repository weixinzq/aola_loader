// 架构角色：诊断模式下把 petfightnew 主 SWF 请求指向 AOLA_BATTLE_BRIDGE_PROBE_SWF 指定的 owner probe 候选。
// 数据流：CEF 战斗主 SWF 请求 -> 环境变量候选 -> LocalResponse；其他资源始终透传。
using System;
using System.IO;
using System.Text.RegularExpressions;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class BattleOwnerProbeResourceRule : IResourceInterceptionRule
{
	internal const string EnvironmentVariable = "AOLA_BATTLE_BRIDGE_PROBE_SWF";
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex BattlePathPattern = new Regex(
		@"^/play/pet/petfightnew~\d+\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private readonly byte[] _content;

	public BattleOwnerProbeResourceRule()
		: this(Environment.GetEnvironmentVariable(EnvironmentVariable))
	{
	}

	internal BattleOwnerProbeResourceRule(string probePath)
	{
		TryLoad(probePath, out _content);
	}

	public string Name => "battle.petfight.owner-probe";

	public int Priority => 851;

	public string PathOwnership => "aola.100bt.com:/play/pet/petfightnew~*.swf";

	public bool IsAvailable => _content != null;

	internal int ContentLength => _content?.Length ?? 0;

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (!IsAvailable || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) ||
			!BattlePathPattern.IsMatch(request.Path))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.LocalResponseOwned(
			request.OriginalUrl,
			_content,
			"application/x-shockwave-flash",
			"battle:petfight:owner-probe:" + _content.Length,
			"battle.petfight.owner-probe");
	}

	private static bool TryLoad(string probePath, out byte[] content)
	{
		content = null;
		if (string.IsNullOrWhiteSpace(probePath))
		{
			return false;
		}
		try
		{
			if (!File.Exists(probePath))
			{
				return false;
			}
			FileInfo file = new FileInfo(probePath);
			if (file.Length < 8 || file.Length > MaximumSwfBytes)
			{
				return false;
			}
			byte[] bytes = File.ReadAllBytes(file.FullName);
			if (bytes.Length < 8 || bytes[0] != 'F' || bytes[1] != 'W' || bytes[2] != 'S' ||
				BitConverter.ToUInt32(bytes, 4) != bytes.Length)
			{
				return false;
			}
			content = bytes;
			return true;
		}
		catch (Exception exception) when (
			exception is IOException ||
			exception is UnauthorizedAccessException ||
			exception is ArgumentException ||
			exception is NotSupportedException)
		{
			content = null;
			return false;
		}
	}
}
