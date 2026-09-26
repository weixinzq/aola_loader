// 架构角色：拥有 petfightnew 主 SWF 路径，仅在 artifact 验证通过时返回本地 bridge。
// 数据流：CEF 资源请求 -> URL/版本匹配 -> 已验证候选或官方 PassThrough。
using System;
using System.Text.RegularExpressions;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class PetFightBattleBridgeResourceRule : IResourceInterceptionRule
{
	private static readonly Regex BattlePathPattern = new Regex(
		@"^/play/pet/petfightnew~(?<version>\d+)\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private readonly PetFightBattleBridgeArtifact _artifact;

	public PetFightBattleBridgeResourceRule(string manifestPath)
	{
		PetFightBattleBridgeArtifact.TryLoad(manifestPath, out _artifact);
	}

	internal PetFightBattleBridgeResourceRule(string manifestJson, byte[] template)
	{
		_artifact = PetFightBattleBridgeArtifact.ParseForTesting(manifestJson, template);
	}

	public string Name => "battle.petfight.bridge";

	public int Priority => 850;

	public string PathOwnership => IsAvailable
		? "aola.100bt.com:/play/pet/petfightnew~" + _artifact.ResourceVersion + ".swf"
		: "aola.100bt.com:/play/pet/petfightnew~unavailable.swf";

	public bool IsAvailable => _artifact != null;

	internal string SupportedVersion => _artifact?.ResourceVersion ?? string.Empty;

	internal string ExpectedTemplateSha256 => _artifact?.CandidateSha256 ?? string.Empty;

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (!IsAvailable || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		Match match = BattlePathPattern.Match(request.Path);
		if (!match.Success ||
			!string.Equals(match.Groups["version"].Value, _artifact.ResourceVersion, StringComparison.Ordinal))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.LocalResponse(
			request.OriginalUrl,
			_artifact.Content,
			"application/x-shockwave-flash",
			"battle:petfight:" + _artifact.ResourceVersion + ":" + _artifact.CandidateSha256,
			"battle.petfight.bridge." + _artifact.ResourceVersion);
	}
}
