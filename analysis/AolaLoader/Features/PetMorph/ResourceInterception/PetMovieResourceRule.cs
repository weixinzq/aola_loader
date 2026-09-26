// 架构角色：拥有普通宠物 movie 请求，将命中的 petId 重写到目标形态远端资源。
// 数据流：资源 URL + 当前规则快照 -> RewriteRemote 或 PassThrough。
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Transformers;

namespace AolaLoader.Features.PetMorph.ResourceInterception;

internal sealed class PetMovieResourceRule : IResourceInterceptionRule
{
	private const string MorphMarkerName = "_aolaMorph";
	private const int HiddenPetMovieTemplateId = 6025;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly int[] KnownTokenCounts = { 45, 39, 36, 36 };
	private static readonly Regex PathPattern = new Regex(
		@"^/play/peticon/movie/type0/petmovie(?<directoryId>\d+)/petmovie(?<fileId>\d+)_(?<part>[0-3])(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private AolaPetMorphRule[] _rules = Array.Empty<AolaPetMorphRule>();
	private int _enabled;

	public string Name => "petmorph.movie.leaf";

	public int Priority => 698;

	public string PathOwnership =>
		"aola.100bt.com:/play/peticon/movie/type0/petmovieN/petmovieN_[0-3]~*.swf";

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
		if (!match.Success ||
			!int.TryParse(match.Groups["directoryId"].Value, out int directoryId) ||
			!int.TryParse(match.Groups["fileId"].Value, out int requestedMovieId) ||
			!int.TryParse(match.Groups["part"].Value, out int part) ||
			directoryId != requestedMovieId)
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		foreach (AolaPetMorphRule rule in Volatile.Read(ref _rules))
		{
			if (rule.OriginalId != requestedMovieId)
			{
				continue;
			}
			int replacementId = rule.HideOriginalModel ? HiddenPetMovieTemplateId : rule.BackpackId;
			if (replacementId <= 0)
			{
				continue;
			}

			string suffix = match.Groups["suffix"].Value;
			string path = "/play/peticon/movie/type0/petmovie" + replacementId +
				"/petmovie" + replacementId + "_" + part + suffix + ".swf";
			string marker = (rule.HideOriginalModel ? "h-" : "m-") +
				requestedMovieId + "-" + replacementId + "-" + part;
			string targetUrl = BuildTargetUrl(request.OriginalUrl, path, marker);
			double scaleFactor = rule.HideOriginalModel
				? 1
				: GetHdScale(replacementId) / GetHdScale(requestedMovieId);
			return ResourceInterceptionPlan.RewriteRemote(
				request.OriginalUrl,
				targetUrl,
				"application/x-shockwave-flash",
				new AolaSwfResourceTransformer(
					"PetMovie" + replacementId,
					"PetMovie" + requestedMovieId,
					GetExpectedTokenCount(replacementId, part),
					scaleFactor,
					makeBitmapsTransparent: rule.HideOriginalModel),
				request.OriginalUrl,
				"petmovie:" + requestedMovieId + ":" + replacementId + ":" + part +
					":" + scaleFactor + ":" + rule.HideOriginalModel,
				"petmorph.movie." + marker,
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

	private static int GetExpectedTokenCount(int replacementId, int part)
	{
		return (replacementId == 5486 || replacementId == 5530) && part >= 0 && part < 4
			? KnownTokenCounts[part]
			: 0;
	}

	private static double GetHdScale(int viewId)
	{
		if (viewId == 5980 || viewId == 5998 || viewId == 5997 || viewId == 6007)
		{
			return 0.4;
		}
		if (viewId == 6000 || viewId == 5994 || viewId == 5995 || viewId == 6044)
		{
			return 0.3;
		}
		return 1;
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
