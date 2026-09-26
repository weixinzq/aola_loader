// 架构角色：按海报目录和形态规则重写宠物 poster 请求，失败时保留官方资源。
// 数据流：poster URL -> petId/catalog/规则匹配 -> RewriteRemote 或 PassThrough。
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Transformers;

namespace AolaLoader.Features.PetMorph.ResourceInterception;

internal sealed class PetPosterResourceRule : IResourceInterceptionRule
{
	private const string MorphMarkerName = "_aolaMorph";
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex PathPattern = new Regex(
		@"^/play/pet/petskin/background/petskinbackground(?<id>\d+)(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private readonly AolaPetPosterCatalog _catalog;
	private AolaPetMorphRule[] _rules = Array.Empty<AolaPetMorphRule>();
	private int _enabled;

	public PetPosterResourceRule(AolaPetPosterCatalog catalog)
	{
		_catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
	}

	public string Name => "petmorph.poster.leaf";

	public int Priority => 697;

	public string PathOwnership =>
		"aola.100bt.com:/play/pet/petskin/background/petskinbackgroundN~*.swf";

	public void SetRules(IEnumerable<AolaPetMorphRule> rules, bool enabled)
	{
		AolaPetMorphRule[] snapshot = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null)
			.Select(CloneRule)
			.ToArray();
		Volatile.Write(ref _rules, snapshot);
		Volatile.Write(ref _enabled, enabled ? 1 : 0);
	}

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (Volatile.Read(ref _enabled) == 0 || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		Match match = PathPattern.Match(request.Path);
		if (!match.Success || !int.TryParse(match.Groups["id"].Value, out int requestedResourceId))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		foreach (AolaPetMorphRule rule in Volatile.Read(ref _rules))
		{
			if (rule.PosterSourceId <= 0 || rule.PosterId <= 0 ||
				!_catalog.TryGetBySkinId(rule.PosterSourceId, out AolaPetPosterCatalogEntry source) ||
				!_catalog.TryGetBySkinId(rule.PosterId, out AolaPetPosterCatalogEntry target) ||
				source.ResourceId != requestedResourceId)
			{
				continue;
			}

			string suffix = match.Groups["suffix"].Value;
			string path = "/play/pet/petskin/background/petskinbackground" +
				target.ResourceId + suffix + ".swf";
			string marker = "p-" + source.ResourceId + "-" + target.ResourceId;
			return ResourceInterceptionPlan.RewriteRemote(
				request.OriginalUrl,
				BuildTargetUrl(request.OriginalUrl, path, marker),
				"application/x-shockwave-flash",
				new AolaSwfResourceTransformer(
					"Background" + target.ResourceId,
					"Background" + source.ResourceId,
					0,
					1,
					structuralClassAdaptation: true),
				request.OriginalUrl,
				"petposter:" + source.ResourceId + ":" + target.ResourceId,
				"petmorph.poster." + marker,
				MaximumSwfBytes);
		}
		return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
	}

	private static string BuildTargetUrl(string originalUrl, string path, string marker)
	{
		Uri uri = new Uri(originalUrl);
		UriBuilder builder = new UriBuilder(uri)
		{
			Path = path,
			Fragment = string.Empty
		};
		string query = uri.Query.TrimStart('?');
		string markerQuery = MorphMarkerName + "=" + Uri.EscapeDataString(marker);
		builder.Query = query.Length == 0 ? markerQuery : query + "&" + markerQuery;
		return builder.Uri.AbsoluteUri;
	}

	private static AolaPetMorphRule CloneRule(AolaPetMorphRule rule)
	{
		return new AolaPetMorphRule(
			rule.Note,
			rule.OriginalId,
			rule.BackpackId,
			rule.PosterSourceId,
			rule.PosterId,
			rule.HideOriginalModel,
			rule.RemoveOriginalBackground,
			rule.ReplaceBackpackIcon);
	}
}
