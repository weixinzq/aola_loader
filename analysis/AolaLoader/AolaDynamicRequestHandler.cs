using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using CefSharp.Handler;

namespace AolaLoader;

internal sealed class AolaThemeRequestHandler : RequestHandler
{
	private const string MorphMarkerName = "_aolaMorph";
	private const string MorphFallbackMarkerName = "_aolaMorphFallback";
	private const int HiddenPetMovieTemplateId = 6025;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private const string SupportedPetPackageVersion = "2026081331982423";
	private const string SupportedPosterResourceSuffix = "~1210";
	private static readonly ConcurrentDictionary<string, ProbeCacheEntry> ProbeCache =
		new ConcurrentDictionary<string, ProbeCacheEntry>(StringComparer.OrdinalIgnoreCase);
	private static readonly Regex PosterPathPattern = new Regex(
		@"^/play/pet/petskin/background/petskinbackground(?<id>\d+)(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly Regex PetMoviePathPattern = new Regex(
		@"^/play/peticon/movie/type0/petmovie(?<directoryId>\d+)/petmovie(?<fileId>\d+)_(?<part>[0-3])(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly Regex PetPackagePathPattern = new Regex(
		@"^/play/pet/newpetpackage~(?<version>\d+)\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly Regex BattlePetPathPattern = new Regex(
		@"^/play/fightassets/bitmap/pet(?<directoryId>\d+)/pet(?<fileId>\d+)_(?<direction>[12])_(?<part>[0-2])(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly int[] KnownPetMovieTokenCounts = { 45, 39, 36, 36 };
	private readonly byte[][] _themes = new byte[10][];
	private int _selectedThemeId = -1;
	private AolaPetMorphRule[] _petMorphRules = Array.Empty<AolaPetMorphRule>();
	private int _petMorphEnabled;
	private AolaBattleMorphRule[] _battleRules = Array.Empty<AolaBattleMorphRule>();
	private int _battleMorphEnabled;
	private readonly AolaPetPosterCatalog _posterCatalog;
	private readonly byte[] _petPackageLiveTemplate;
	private readonly bool _petMorphLiveBridgeEnabled;

	public AolaThemeRequestHandler(
		string themeDirectory,
		string posterCatalogPath = null,
		string petPackageLiveTemplatePath = null,
		bool petMorphLiveBridgeEnabled = true)
	{
		_posterCatalog = AolaPetPosterCatalog.Load(posterCatalogPath);
		_petMorphLiveBridgeEnabled = petMorphLiveBridgeEnabled;
		if (_petMorphLiveBridgeEnabled &&
			!string.IsNullOrEmpty(petPackageLiveTemplatePath) &&
			File.Exists(petPackageLiveTemplatePath))
		{
			byte[] template = File.ReadAllBytes(petPackageLiveTemplatePath);
			if (AolaSwfResponseFilter.IsValidFws(template) &&
				CountOccurrences(template, Encoding.ASCII.GetBytes("aolaMorphResolveSkinId")) >= 1 &&
				CountOccurrences(template, Encoding.ASCII.GetBytes("aolaMorphRefresh")) >= 1 &&
				CountOccurrences(template, Encoding.ASCII.GetBytes("aolaMorphShouldHideBackground")) >= 1 &&
				CountOccurrences(template, Encoding.ASCII.GetBytes("aolaMorphResolveIconId")) >= 1)
			{
				_petPackageLiveTemplate = template;
			}
		}
		for (int themeId = 0; themeId < _themes.Length; themeId++)
		{
			string path = Path.Combine(themeDirectory ?? string.Empty, "skin" + themeId + ".swf");
			if (!File.Exists(path))
			{
				continue;
			}
			byte[] content = File.ReadAllBytes(path);
			if (AolaSwfResponseFilter.IsValidFws(content))
			{
				_themes[themeId] = content;
			}
		}
	}

	public int SelectedThemeId
	{
		get => Volatile.Read(ref _selectedThemeId);
		set
		{
			if (value < -1 || value >= _themes.Length)
			{
				throw new ArgumentOutOfRangeException(nameof(value));
			}
			if (value >= 0 && _themes[value] == null)
			{
				throw new InvalidOperationException("找不到主题 " + value + " 的本地 SWF。");
			}
			Volatile.Write(ref _selectedThemeId, value);
		}
	}

	public void SetPetMorphRules(IEnumerable<AolaPetMorphRule> rules, bool enabled)
	{
		AolaPetMorphRule[] snapshot = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Select(rule => new AolaPetMorphRule(
				rule.Note, rule.OriginalId, rule.BackpackId, rule.PosterSourceId, rule.PosterId,
				rule.HideOriginalModel, rule.RemoveOriginalBackground, rule.ReplaceBackpackIcon))
			.ToArray();
		Volatile.Write(ref _petMorphRules, snapshot);
		Volatile.Write(ref _petMorphEnabled, enabled ? 1 : 0);
	}

	public bool IsPetMorphLiveBridgeAvailable => _petPackageLiveTemplate != null;

	public void SetBattleMorphRules(IEnumerable<AolaBattleMorphRule> rules, bool enabled)
	{
		AolaBattleMorphRule[] snapshot = (rules ?? Enumerable.Empty<AolaBattleMorphRule>())
			.Where(rule => rule != null && rule.Enabled &&
				rule.SourceId > 0 && rule.TargetId > 0 && rule.SourceId != rule.TargetId &&
				rule.SourceId.ToString().Length == rule.TargetId.ToString().Length)
			.Select(rule => new AolaBattleMorphRule(
				rule.Note, rule.SourceId, rule.TargetId, rule.Scope, true))
			.ToArray();
		Volatile.Write(ref _battleRules, snapshot);
		Volatile.Write(ref _battleMorphEnabled, enabled ? 1 : 0);
	}

	public string ValidateBattleMorphRule(AolaBattleMorphRule rule)
	{
		if (rule == null || rule.SourceId <= 0 || rule.TargetId <= 0 || rule.SourceId == rule.TargetId)
		{
			return "战斗模型源 ID 和目标 ID 必须填写且不同。";
		}
		if (rule.SourceId.ToString().Length != rule.TargetId.ToString().Length)
		{
			return "战斗模型源 ID 与目标 ID 的位数必须一致，以保持类名长度不变。";
		}
		if (rule.SourceId < 4400 || rule.TargetId < 4400)
		{
			return "战斗模型替换当前仅支持 ID 大于等于 4400 的多分片战斗模型。";
		}
		return null;
	}

	public async Task<IReadOnlyDictionary<int, int>> GetAvailableLivePosterMappingsAsync(
		IEnumerable<AolaPetMorphRule> rules,
		bool enabled)
	{
		if (!enabled || !_petMorphLiveBridgeEnabled || _petPackageLiveTemplate == null)
		{
			return new Dictionary<int, int>();
		}

		KeyValuePair<int, int>[] candidates = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.PosterId > 0)
			.Select(rule => new KeyValuePair<int, int>(
				rule.PosterSourceId > 0 ? rule.PosterSourceId : rule.OriginalId,
				rule.PosterId))
			.Where(pair => pair.Key > 0 && pair.Value > 0)
			.GroupBy(pair => pair.Key)
			.Select(group => group.Last())
			.ToArray();

		Task<KeyValuePair<int, int>?>[] probes = candidates.Select(async pair =>
		{
			if (!_posterCatalog.TryGetBySkinId(pair.Value, out AolaPetPosterCatalogEntry target))
			{
				return (KeyValuePair<int, int>?)null;
			}
			string url = "https://aola.100bt.com/play/pet/petskin/background/petskinbackground" +
				target.ResourceId + SupportedPosterResourceSuffix + ".swf";
			bool available;
			if (!TryGetCachedProbe(url, out available))
			{
				available = await Task.Run(() => ProbeRemoteSwf(url)).ConfigureAwait(false);
				CacheProbe(url, available);
			}
			return available ? pair : (KeyValuePair<int, int>?)null;
		}).ToArray();

		KeyValuePair<int, int>?[] results = await Task.WhenAll(probes).ConfigureAwait(false);
		return results.Where(item => item.HasValue)
			.Select(item => item.Value)
			.ToDictionary(pair => pair.Key, pair => pair.Value);
	}

	public string ValidatePetMorphRule(AolaPetMorphRule rule)
	{
		if (rule == null || (rule.BackpackId <= 0 && rule.PosterId <= 0 &&
			!rule.HideOriginalModel && !rule.RemoveOriginalBackground && !rule.ReplaceBackpackIcon))
		{
			return "原型 ID 无效。";
		}
		if (rule.RemoveOriginalBackground && rule.OriginalId <= 0)
		{
			return "移除原背景时必须填写模型源 ID。";
		}
		if (rule.ReplaceBackpackIcon && (rule.OriginalId <= 0 || rule.BackpackId <= 0))
		{
			return "替换背包头像时必须同时填写模型源 ID 和模型目标 ID。";
		}
		if (rule.BackpackId > 0 || rule.HideOriginalModel)
		{
			if (rule.OriginalId < 4400 || rule.BackpackId > 0 && rule.BackpackId < 4400)
			{
				return "背包动态模型仅支持 ID 大于等于 4400；较旧 ID 使用另一套静态资源格式。";
			}
			if (rule.BackpackId > 0 &&
				rule.OriginalId.ToString().Length != rule.BackpackId.ToString().Length)
			{
				return "背包原型 ID 与替换 ID 的位数必须一致，以保持 SWF 类名长度不变。";
			}
			if (rule.HideOriginalModel && rule.BackpackId > 0)
			{
				return "隐藏原模型与模型目标 ID 不能同时启用。";
			}
			if (rule.HideOriginalModel &&
				rule.OriginalId.ToString().Length != HiddenPetMovieTemplateId.ToString().Length)
			{
				return "隐藏原模型当前仅支持与透明模板同为 4 位数的模型 ID。";
			}
		}
		if (rule.PosterId > 0)
		{
			if (!_posterCatalog.IsAvailable)
			{
				return "Poster catalog is unavailable: " + (_posterCatalog.Error ?? "empty catalog");
			}
			if (rule.PosterSourceId > 0 &&
				!_posterCatalog.TryGetBySkinId(rule.PosterSourceId, out _))
			{
				return "Poster source skin ID is not present in the complete Background catalog.";
			}
			if (!_posterCatalog.TryGetBySkinId(rule.PosterId, out _))
			{
				return "Poster target skin ID is not present in the complete Background catalog.";
			}
			if (rule.PosterSourceId <= 0 && rule.OriginalId <= 0)
			{
				return "模型形态转海报时必须填写模型源 ID。";
			}
			return null;
		}
		return null;
	}

	protected override IResourceRequestHandler GetResourceRequestHandler(
		IWebBrowser chromiumWebBrowser,
		IBrowser browser,
		IFrame frame,
		IRequest request,
		bool isNavigation,
		bool isDownload,
		string requestInitiator,
		ref bool disableDefaultHandling)
	{
		int selectedThemeId = SelectedThemeId;
		if (selectedThemeId >= 0 && TryGetRequestedSkinId(request?.Url, out int requestedSkinId))
		{
			byte[] response = CreateSkinResponse(selectedThemeId, requestedSkinId);
			if (response != null)
			{
				disableDefaultHandling = true;
				return new SwfResourceRequestHandler(response);
			}
		}

		if (HasQueryMarker(request?.Url, MorphFallbackMarkerName))
		{
			return null;
		}
		if (TryCreateMarkedPlan(request?.Url, out RemoteSwfPlan markedPlan))
		{
			return new RemoteSwfResourceRequestHandler(markedPlan, true);
		}
		if (TryCreatePetPackageLiveResponse(request?.Url, out byte[] packageResponse))
		{
			disableDefaultHandling = true;
			return new SwfResourceRequestHandler(packageResponse);
		}
		if (Volatile.Read(ref _petMorphEnabled) == 0)
		{
			return null;
		}

		AolaPetMorphRule[] rules = Volatile.Read(ref _petMorphRules);
		RemoteSwfPlan plan = null;
		if (TryGetRequestedPoster(request?.Url, out Uri posterUri, out int posterResourceId, out string posterSuffix))
		{
			plan = CreatePosterPlan(rules, posterUri, posterResourceId, posterSuffix);
		}
		else if (TryGetRequestedPetMovie(request?.Url, out Uri movieUri, out int movieId, out int part, out string movieSuffix))
		{
			plan = CreatePetMoviePlan(rules, movieUri, movieId, part, movieSuffix);
		}
		else if (TryGetRequestedBattlePet(request?.Url, out Uri battleUri, out int battleId, out int direction, out int battlePart, out string battleSuffix))
		{
			plan = CreateBattlePetPlan(Volatile.Read(ref _battleRules), battleUri, battleId, direction, battlePart, battleSuffix);
		}
		return plan == null ? null : new RemoteSwfResourceRequestHandler(plan, false);
	}

	private bool TryCreatePetPackageLiveResponse(string url, out byte[] response)
	{
		response = null;
		if (_petPackageLiveTemplate == null || !TryGetAolaUri(url, out Uri uri))
		{
			return false;
		}
		Match match = PetPackagePathPattern.Match(uri.AbsolutePath);
		if (!match.Success ||
			!string.Equals(match.Groups["version"].Value, SupportedPetPackageVersion, StringComparison.Ordinal))
		{
			return false;
		}

		response = (byte[])_petPackageLiveTemplate.Clone();
		return true;
	}

	private static int CountOccurrences(byte[] content, byte[] value)
	{
		if (content == null || value == null || value.Length == 0)
		{
			return 0;
		}
		int count = 0;
		for (int i = 0; i <= content.Length - value.Length; i++)
		{
			bool match = true;
			for (int j = 0; j < value.Length; j++)
			{
				if (content[i + j] != value[j])
				{
					match = false;
					break;
				}
			}
			if (match)
			{
				count++;
				i += value.Length - 1;
			}
		}
		return count;
	}

	private byte[] CreateSkinResponse(int selectedThemeId, int requestedSkinId)
	{
		byte[] source = _themes[selectedThemeId];
		if (source == null)
		{
			return null;
		}
		byte[] response = (byte[])source.Clone();
		int replacements = ReplaceSameLength(
			response,
			Encoding.ASCII.GetBytes("Skin" + selectedThemeId),
			Encoding.ASCII.GetBytes("Skin" + requestedSkinId));
		return replacements == 0 ? null : response;
	}

	private RemoteSwfPlan CreatePosterPlan(
		AolaPetMorphRule[] rules,
		Uri requestedUri,
		int requestedResourceId,
		string suffix)
	{
		foreach (AolaPetMorphRule rule in rules)
		{
			if (rule.PosterSourceId <= 0 || rule.PosterId <= 0 ||
				!_posterCatalog.TryGetBySkinId(rule.PosterSourceId, out AolaPetPosterCatalogEntry source) ||
				!_posterCatalog.TryGetBySkinId(rule.PosterId, out AolaPetPosterCatalogEntry target) ||
				source.ResourceId != requestedResourceId)
			{
				continue;
			}

			string path = "/play/pet/petskin/background/petskinbackground" +
				target.ResourceId + suffix + ".swf";
			return new RemoteSwfPlan(
				requestedUri.AbsoluteUri,
				BuildRemoteUrl(requestedUri, path, "p-" + source.ResourceId + "-" + target.ResourceId),
				"Background" + target.ResourceId,
				"Background" + source.ResourceId,
				0,
				1,
				true);
		}
		return null;
	}

	private static RemoteSwfPlan CreatePetMoviePlan(
		AolaPetMorphRule[] rules,
		Uri requestedUri,
		int requestedMovieId,
		int part,
		string suffix)
	{
		foreach (AolaPetMorphRule rule in rules)
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
			string path = "/play/peticon/movie/type0/petmovie" + replacementId +
				"/petmovie" + replacementId + "_" + part + suffix + ".swf";
			string marker = (rule.HideOriginalModel ? "h-" : "m-") +
				requestedMovieId + "-" + replacementId + "-" + part;
			return new RemoteSwfPlan(
				requestedUri.AbsoluteUri,
				BuildRemoteUrl(requestedUri, path, marker),
				"PetMovie" + replacementId,
				"PetMovie" + requestedMovieId,
				GetExpectedPetMovieTokenCount(replacementId, part),
				rule.HideOriginalModel ? 1 :
					GetPetMovieHdScale(replacementId) / GetPetMovieHdScale(requestedMovieId),
				false,
				rule.HideOriginalModel);
		}
		return null;
	}

	private static RemoteSwfPlan CreateBattlePetPlan(
		AolaBattleMorphRule[] rules,
		Uri requestedUri,
		int requestedBattleId,
		int direction,
		int part,
		string suffix)
	{
		foreach (AolaBattleMorphRule rule in rules)
		{
			if (rule.SourceId != requestedBattleId || !MatchesDirection(rule.Scope, direction))
			{
				continue;
			}
			string path = "/play/fightassets/bitmap/pet" + rule.TargetId +
				"/pet" + rule.TargetId + "_" + direction + "_" + part + suffix + ".swf";
			string marker = "b-" + requestedBattleId + "-" + rule.TargetId + "-" + direction + "-" + part;
			return new RemoteSwfPlan(
				requestedUri.AbsoluteUri,
				BuildRemoteUrl(requestedUri, path, marker),
				"Pet" + rule.TargetId,
				"Pet" + requestedBattleId,
				0,
				1,
				false,
				false,
				requestedBattleId,
				rule.TargetId);
		}
		return null;
	}

	private static bool MatchesDirection(BattleScope scope, int direction)
	{
		// _1_* = positive/enemy face, _2_* = back/self face (see evidence README).
		return scope == BattleScope.Both ||
			(scope == BattleScope.Self && direction == 2) ||
			(scope == BattleScope.Enemy && direction == 1);
	}

	private static string BuildRemoteUrl(Uri requestedUri, string path, string marker)
	{
		UriBuilder builder = new UriBuilder(requestedUri)
		{
			Path = path,
			Fragment = string.Empty
		};
		string query = requestedUri.Query.TrimStart('?');
		string markerQuery = MorphMarkerName + "=" + Uri.EscapeDataString(marker);
		builder.Query = query.Length == 0 ? markerQuery : query + "&" + markerQuery;
		return builder.Uri.AbsoluteUri;
	}

	private static bool TryCreateMarkedPlan(string url, out RemoteSwfPlan plan)
	{
		plan = null;
		if (!TryGetAolaUri(url, out Uri uri) ||
			!TryGetQueryValue(uri.Query, MorphMarkerName, out string marker))
		{
			return false;
		}

		string[] parts = marker.Split('-');
		if (parts.Length == 4 && (parts[0] == "m" || parts[0] == "h") &&
			int.TryParse(parts[1], out int originalMovieId) &&
			int.TryParse(parts[2], out int replacementMovieId) &&
			int.TryParse(parts[3], out int markerPart) &&
			(parts[0] != "h" || replacementMovieId == HiddenPetMovieTemplateId) &&
			TryGetRequestedPetMovie(url, out _, out int requestedMovieId, out int requestedPart, out string suffix) &&
			requestedMovieId == replacementMovieId && requestedPart == markerPart)
		{
			string originalPath = "/play/peticon/movie/type0/petmovie" + originalMovieId +
				"/petmovie" + originalMovieId + "_" + markerPart + suffix + ".swf";
			plan = new RemoteSwfPlan(
				BuildUrlWithoutMorphMarker(uri, originalPath),
				uri.AbsoluteUri,
				"PetMovie" + replacementMovieId,
				"PetMovie" + originalMovieId,
				GetExpectedPetMovieTokenCount(replacementMovieId, markerPart),
				parts[0] == "h" ? 1 :
					GetPetMovieHdScale(replacementMovieId) / GetPetMovieHdScale(originalMovieId),
				false,
				parts[0] == "h");
			return true;
		}

		if (parts.Length == 3 && parts[0] == "p" &&
			int.TryParse(parts[1], out int originalResourceId) &&
			int.TryParse(parts[2], out int replacementResourceId) &&
			TryGetRequestedPoster(url, out _, out int requestedResourceId, out string posterSuffix) &&
			requestedResourceId == replacementResourceId)
		{
			string originalPath = "/play/pet/petskin/background/petskinbackground" +
				originalResourceId + posterSuffix + ".swf";
			plan = new RemoteSwfPlan(
				BuildUrlWithoutMorphMarker(uri, originalPath),
				uri.AbsoluteUri,
				"Background" + replacementResourceId,
				"Background" + originalResourceId,
				0,
				1,
				true);
			return true;
		}

		if (parts.Length == 5 && parts[0] == "b" &&
			int.TryParse(parts[1], out int originalBattleId) &&
			int.TryParse(parts[2], out int replacementBattleId) &&
			int.TryParse(parts[3], out int battleMarkerDirection) &&
			int.TryParse(parts[4], out int battleMarkerPart) &&
			TryGetRequestedBattlePet(url, out _, out int battleRequestedId, out int battleRequestedDirection, out int battleRequestedPart, out string battleSuffix) &&
			battleRequestedId == replacementBattleId && battleRequestedDirection == battleMarkerDirection && battleRequestedPart == battleMarkerPart)
		{
			string originalPath = "/play/fightassets/bitmap/pet" + originalBattleId +
				"/pet" + originalBattleId + "_" + battleMarkerDirection + "_" + battleMarkerPart + battleSuffix + ".swf";
			plan = new RemoteSwfPlan(
				BuildUrlWithoutMorphMarker(uri, originalPath),
				uri.AbsoluteUri,
				"Pet" + replacementBattleId,
				"Pet" + originalBattleId,
				0,
				1,
				false,
				false,
				originalBattleId,
				replacementBattleId);
			return true;
		}
		return false;
	}

	private static string BuildUrlWithoutMorphMarker(Uri uri, string path)
	{
		UriBuilder builder = new UriBuilder(uri)
		{
			Path = path,
			Query = RemoveQueryValue(uri.Query, MorphMarkerName),
			Fragment = string.Empty
		};
		return builder.Uri.AbsoluteUri;
	}

	private static string BuildFallbackUrl(string originalUrl)
	{
		Uri uri = new Uri(originalUrl);
		UriBuilder builder = new UriBuilder(uri);
		string query = uri.Query.TrimStart('?');
		string marker = MorphFallbackMarkerName + "=1";
		builder.Query = query.Length == 0 ? marker : query + "&" + marker;
		return builder.Uri.AbsoluteUri;
	}

	private static bool TryGetQueryValue(string query, string name, out string value)
	{
		value = null;
		foreach (string item in query.TrimStart('?').Split('&'))
		{
			if (item.Length == 0)
			{
				continue;
			}
			int equals = item.IndexOf('=');
			string itemName = equals < 0 ? item : item.Substring(0, equals);
			if (!string.Equals(Uri.UnescapeDataString(itemName), name, StringComparison.OrdinalIgnoreCase))
			{
				continue;
			}
			value = equals < 0 ? string.Empty : Uri.UnescapeDataString(item.Substring(equals + 1));
			return true;
		}
		return false;
	}

	private static string RemoveQueryValue(string query, string name)
	{
		return string.Join("&", query.TrimStart('?').Split('&').Where(item =>
		{
			int equals = item.IndexOf('=');
			string itemName = equals < 0 ? item : item.Substring(0, equals);
			return item.Length > 0 &&
				!string.Equals(Uri.UnescapeDataString(itemName), name, StringComparison.OrdinalIgnoreCase);
		}));
	}

	private static int GetExpectedPetMovieTokenCount(int replacementId, int part)
	{
		return (replacementId == 5486 || replacementId == 5530) && part >= 0 && part < 4
			? KnownPetMovieTokenCounts[part]
			: 0;
	}

	private static double GetPetMovieHdScale(int viewId)
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

	private static int ReplaceSameLength(byte[] content, byte[] search, byte[] replacement)
	{
		if (search.Length != replacement.Length)
		{
			throw new ArgumentException("SWF 类名替换必须保持长度一致。", nameof(replacement));
		}
		int count = 0;
		for (int offset = 0; offset <= content.Length - search.Length; offset++)
		{
			bool match = true;
			for (int index = 0; index < search.Length; index++)
			{
				if (content[offset + index] != search[index])
				{
					match = false;
					break;
				}
			}
			if (!match)
			{
				continue;
			}
			Buffer.BlockCopy(replacement, 0, content, offset, replacement.Length);
			count++;
			offset += search.Length - 1;
		}
		return count;
	}

	private static bool TryGetRequestedSkinId(string url, out int skinId)
	{
		skinId = -1;
		if (!TryGetAolaUri(url, out Uri uri) ||
			!uri.AbsolutePath.StartsWith("/play/control/controlbarskin/", StringComparison.OrdinalIgnoreCase))
		{
			return false;
		}
		string fileName = Path.GetFileName(uri.AbsolutePath);
		if (fileName.Length < 9 || !fileName.StartsWith("skin", StringComparison.OrdinalIgnoreCase) ||
			fileName[4] < '0' || fileName[4] > '9' ||
			(fileName[5] != '~' && fileName[5] != '.'))
		{
			return false;
		}
		skinId = fileName[4] - '0';
		return fileName.EndsWith(".swf", StringComparison.OrdinalIgnoreCase);
	}

	private static bool TryGetRequestedPoster(
		string url,
		out Uri uri,
		out int posterId,
		out string suffix)
	{
		posterId = -1;
		suffix = string.Empty;
		if (!TryGetAolaUri(url, out uri))
		{
			return false;
		}
		Match match = PosterPathPattern.Match(uri.AbsolutePath);
		if (!match.Success || !int.TryParse(match.Groups["id"].Value, out posterId))
		{
			return false;
		}
		suffix = match.Groups["suffix"].Value;
		return true;
	}

	private static bool TryGetRequestedPetMovie(
		string url,
		out Uri uri,
		out int movieId,
		out int part,
		out string suffix)
	{
		movieId = -1;
		part = -1;
		suffix = string.Empty;
		if (!TryGetAolaUri(url, out uri))
		{
			return false;
		}
		Match match = PetMoviePathPattern.Match(uri.AbsolutePath);
		if (!match.Success ||
			!int.TryParse(match.Groups["directoryId"].Value, out int directoryId) ||
			!int.TryParse(match.Groups["fileId"].Value, out movieId) ||
			!int.TryParse(match.Groups["part"].Value, out part))
		{
			return false;
		}
		suffix = match.Groups["suffix"].Value;
		return directoryId == movieId;
	}

	private static bool TryGetRequestedBattlePet(
		string url,
		out Uri uri,
		out int battleId,
		out int direction,
		out int part,
		out string suffix)
	{
		battleId = -1;
		direction = -1;
		part = -1;
		suffix = string.Empty;
		if (!TryGetAolaUri(url, out uri))
		{
			return false;
		}
		Match match = BattlePetPathPattern.Match(uri.AbsolutePath);
		if (!match.Success ||
			!int.TryParse(match.Groups["directoryId"].Value, out int directoryId) ||
			!int.TryParse(match.Groups["fileId"].Value, out battleId) ||
			!int.TryParse(match.Groups["direction"].Value, out direction) ||
			!int.TryParse(match.Groups["part"].Value, out part))
		{
			return false;
		}
		suffix = match.Groups["suffix"].Value;
		return directoryId == battleId;
	}

	private static bool TryGetAolaUri(string url, out Uri uri)
	{
		return Uri.TryCreate(url, UriKind.Absolute, out uri) &&
			string.Equals(uri.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase);
	}

	private static bool HasQueryMarker(string url, string markerName)
	{
		return Uri.TryCreate(url, UriKind.Absolute, out Uri uri) &&
			TryGetQueryValue(uri.Query, markerName, out _);
	}

	private sealed class RemoteSwfPlan
	{
		public RemoteSwfPlan(
			string originalUrl,
			string remoteUrl,
			string sourceToken,
			string targetToken,
			int expectedCount,
			double scaleFactor,
			bool structuralClassAdaptation = false,
			bool makeBitmapsTransparent = false,
			int battleSourceId = 0,
			int battleTargetId = 0)
		{
			OriginalUrl = originalUrl;
			RemoteUrl = remoteUrl;
			SourceToken = sourceToken;
			TargetToken = targetToken;
			ExpectedCount = expectedCount;
			ScaleFactor = scaleFactor;
			StructuralClassAdaptation = structuralClassAdaptation;
			MakeBitmapsTransparent = makeBitmapsTransparent;
			BattleSourceId = battleSourceId;
			BattleTargetId = battleTargetId;
		}

		public string OriginalUrl { get; }
		public string RemoteUrl { get; }
		public string SourceToken { get; }
		public string TargetToken { get; }
		public int ExpectedCount { get; }
		public double ScaleFactor { get; }
		public bool StructuralClassAdaptation { get; }
		public bool MakeBitmapsTransparent { get; }
		public int BattleSourceId { get; }
		public int BattleTargetId { get; }
	}

	private sealed class RemoteSwfResourceRequestHandler : ResourceRequestHandler
	{
		private readonly RemoteSwfPlan _plan;
		private readonly bool _alreadyRewritten;
		private int _usingOriginal;

		public RemoteSwfResourceRequestHandler(RemoteSwfPlan plan, bool alreadyRewritten)
		{
			_plan = plan;
			_alreadyRewritten = alreadyRewritten;
		}

		protected override CefReturnValue OnBeforeResourceLoad(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IRequestCallback callback)
		{
			if (_alreadyRewritten)
			{
				return CefReturnValue.Continue;
			}
			if (TryGetCachedProbe(_plan.RemoteUrl, out bool available))
			{
				ApplyProbeResult(request, available);
				return CefReturnValue.Continue;
			}

			Task.Run(() => ProbeAndContinue(request, callback));
			return CefReturnValue.ContinueAsync;
		}

		private void ProbeAndContinue(IRequest request, IRequestCallback callback)
		{
			bool available = ProbeRemoteSwf(_plan.RemoteUrl);
			CacheProbe(_plan.RemoteUrl, available);
			ApplyProbeResult(request, available);
			try
			{
				if (!callback.IsDisposed)
				{
					callback.Continue(true);
				}
			}
			finally
			{
				callback.Dispose();
			}
		}

		private void ApplyProbeResult(IRequest request, bool available)
		{
			if (available)
			{
				request.Url = _plan.RemoteUrl;
			}
			else
			{
				Interlocked.Exchange(ref _usingOriginal, 1);
			}
		}

		protected override bool OnResourceResponse(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response)
		{
			if (Volatile.Read(ref _usingOriginal) == 0 &&
				(response == null || response.StatusCode < 200 || response.StatusCode >= 300))
			{
				CacheProbe(_plan.RemoteUrl, false);
				Interlocked.Exchange(ref _usingOriginal, 1);
				request.Url = BuildFallbackUrl(_plan.OriginalUrl);
				return true;
			}
			return false;
		}

		protected override IResponseFilter GetResourceResponseFilter(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response)
		{
			if (Volatile.Read(ref _usingOriginal) != 0 || response == null || response.StatusCode != 200)
			{
				return null;
			}
			return new AolaSwfResponseFilter(
				_plan.SourceToken,
				_plan.TargetToken,
				_plan.ExpectedCount,
				_plan.ScaleFactor,
				_plan.StructuralClassAdaptation,
				_plan.MakeBitmapsTransparent,
				_plan.BattleSourceId,
				_plan.BattleTargetId);
		}
	}

	private static bool TryGetCachedProbe(string url, out bool available)
	{
		available = false;
		if (!ProbeCache.TryGetValue(url, out ProbeCacheEntry entry))
		{
			return false;
		}
		if (entry.ExpiresUtc <= DateTime.UtcNow)
		{
			ProbeCache.TryRemove(url, out _);
			return false;
		}
		available = entry.Available;
		return true;
	}

	private static void CacheProbe(string url, bool available)
	{
		ProbeCache[url] = new ProbeCacheEntry(
			available,
			DateTime.UtcNow + (available ? TimeSpan.FromMinutes(10) : TimeSpan.FromSeconds(30)));
	}

	private static bool ProbeRemoteSwf(string url)
	{
		try
		{
			HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
			request.Method = "GET";
			request.AddRange(0, 16);
			request.AllowAutoRedirect = true;
			request.AutomaticDecompression = DecompressionMethods.None;
			request.Timeout = 5000;
			request.ReadWriteTimeout = 5000;
			request.UserAgent = "AolaLoader/4.0";
			using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
			{
				if (response.StatusCode != HttpStatusCode.PartialContent && response.StatusCode != HttpStatusCode.OK)
				{
					return false;
				}
				byte[] header = new byte[17];
				int offset = 0;
				using (Stream stream = response.GetResponseStream())
				{
					while (stream != null && offset < header.Length)
					{
						int read = stream.Read(header, offset, header.Length - offset);
						if (read <= 0)
						{
							break;
						}
						offset += read;
					}
				}
				long responseLength = GetTotalResponseLength(response);
				return IsSupportedRemoteSwfHeader(header, offset, responseLength);
			}
		}
		catch (WebException)
		{
			return false;
		}
		catch (IOException)
		{
			return false;
		}
	}

	internal static bool IsSupportedRemoteSwfHeader(byte[] header, int count, long responseLength)
	{
		if (header == null || count < 8 || count > header.Length || responseLength < 8 ||
			responseLength > MaximumSwfBytes)
		{
			return false;
		}
		uint declaredLength = BitConverter.ToUInt32(header, 4);
		if (declaredLength < 8 || declaredLength > MaximumSwfBytes)
		{
			return false;
		}
		bool isFws = header[0] == 'F' && header[1] == 'W' && header[2] == 'S';
		bool isCws = header[0] == 'C' && header[1] == 'W' && header[2] == 'S';
		bool isZws = count >= 17 && header[0] == 'Z' && header[1] == 'W' && header[2] == 'S';
		if (isFws)
		{
			return responseLength == declaredLength;
		}
		if (isCws)
		{
			return true;
		}
		if (!isZws)
		{
			return false;
		}
		uint compressedLength = BitConverter.ToUInt32(header, 8);
		uint dictionarySize = BitConverter.ToUInt32(header, 13);
		return responseLength >= 17 && compressedLength == responseLength - 17 &&
			dictionarySize > 0 && dictionarySize <= 64 * 1024 * 1024;
	}

	private static long GetTotalResponseLength(HttpWebResponse response)
	{
		string contentRange = response.Headers[HttpResponseHeader.ContentRange];
		if (!string.IsNullOrEmpty(contentRange))
		{
			int slash = contentRange.LastIndexOf('/');
			if (slash >= 0 && long.TryParse(contentRange.Substring(slash + 1), out long total))
			{
				return total;
			}
		}
		return response.ContentLength;
	}

	private sealed class ProbeCacheEntry
	{
		public ProbeCacheEntry(bool available, DateTime expiresUtc)
		{
			Available = available;
			ExpiresUtc = expiresUtc;
		}

		public bool Available { get; }
		public DateTime ExpiresUtc { get; }
	}

	private sealed class SwfResourceRequestHandler : ResourceRequestHandler
	{
		private readonly byte[] _content;

		public SwfResourceRequestHandler(byte[] content)
		{
			_content = content;
		}

		protected override IResourceHandler GetResourceHandler(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request)
		{
			return ResourceHandler.FromByteArray(_content, "application/x-shockwave-flash");
		}
	}
}
