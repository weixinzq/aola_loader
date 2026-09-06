using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class BattlePetMovieResourceRule : IResourceInterceptionRule
{
	private static readonly Regex PathPattern = new Regex(
		@"^/play/fightassets/bitmap/pet(?<directory>\d+)/pet(?<file>\d+)_(?<face>[12])_(?<part>[0-2])~(?<version>[^/]+)\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private PreparedBattleMorphRule[] _rules = Array.Empty<PreparedBattleMorphRule>();
	private int _enabled;

	public string Name => "battle.petmovie.leaf";
	public int Priority => 697;
	public string PathOwnership => "aola.100bt.com:/play/fightassets/bitmap/petN/petN_[12]_[0-2]~*.swf";

	public void SetRules(IEnumerable<PreparedBattleMorphRule> rules, bool enabled)
	{
		Volatile.Write(ref _rules, (rules ?? Enumerable.Empty<PreparedBattleMorphRule>()).ToArray());
		Volatile.Write(ref _enabled, enabled ? 1 : 0);
	}

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null) throw new ArgumentNullException(nameof(request));
		if (Volatile.Read(ref _enabled) == 0 || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}
		Match match = PathPattern.Match(request.Path);
		if (!match.Success || match.Groups["directory"].Value != match.Groups["file"].Value ||
			!int.TryParse(match.Groups["file"].Value, out int sourceId) ||
			!int.TryParse(match.Groups["face"].Value, out int face) ||
			!int.TryParse(match.Groups["part"].Value, out int part))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}
		PreparedBattleMorphRule rule = Volatile.Read(ref _rules).FirstOrDefault(item => item.SourceViewId == sourceId);
		if (rule == null || !rule.TryGetResource(face, part, out string targetVersion, out byte[] content))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}
		return ResourceInterceptionPlan.LocalResponse(
			request.OriginalUrl,
			content,
			"application/x-shockwave-flash",
			"battle-petmovie:" + sourceId + ":" + rule.TargetViewId + ":" + face + ":" + part + ":" + targetVersion,
			"battle.petmovie." + sourceId + "." + rule.TargetViewId + "." + face + "." + part);
	}
}

internal sealed class PreparedBattleMorphRule
{
	private readonly IReadOnlyDictionary<int, string> _versions;
	private readonly IReadOnlyDictionary<int, byte[]> _contents;

	public PreparedBattleMorphRule(
		BattleMorphRule rule,
		IReadOnlyDictionary<int, string> versions,
		IReadOnlyDictionary<int, byte[]> contents)
	{
		SourceViewId = rule.SourceViewId;
		TargetViewId = rule.TargetViewId;
		_versions = versions.ToDictionary(pair => pair.Key, pair => pair.Value);
		_contents = contents.ToDictionary(pair => pair.Key, pair => (byte[])pair.Value.Clone());
	}

	public int SourceViewId { get; }
	public int TargetViewId { get; }

	public bool TryGetResource(int face, int part, out string version, out byte[] content)
	{
		int key = face * 10 + part;
		if (!_versions.TryGetValue(key, out version) || !_contents.TryGetValue(key, out byte[] stored))
		{
			content = null;
			return false;
		}
		content = (byte[])stored.Clone();
		return true;
	}
}
