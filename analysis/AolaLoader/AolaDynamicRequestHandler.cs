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
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly ConcurrentDictionary<string, ProbeCacheEntry> ProbeCache =
		new ConcurrentDictionary<string, ProbeCacheEntry>(StringComparer.OrdinalIgnoreCase);
	private static readonly Regex PosterPathPattern = new Regex(
		@"^/play/pet/petskin/background/petskinbackground(?<id>\d+)(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly Regex PetMoviePathPattern = new Regex(
		@"^/play/peticon/movie/type0/petmovie(?<directoryId>\d+)/petmovie(?<fileId>\d+)_(?<part>[0-3])(?<suffix>~[^/]+)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly int[] KnownPetMovieTokenCounts = { 45, 39, 36, 36 };
	private readonly byte[][] _themes = new byte[10][];
	private int _selectedThemeId = -1;
	private AolaPetMorphRule[] _petMorphRules = Array.Empty<AolaPetMorphRule>();
	private int _petMorphEnabled;

	public AolaThemeRequestHandler(string themeDirectory)
	{
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
			.Select(rule => new AolaPetMorphRule(rule.Note, rule.OriginalId, rule.BackpackId, rule.PosterId))
			.ToArray();
		Volatile.Write(ref _petMorphRules, snapshot);
		Volatile.Write(ref _petMorphEnabled, enabled ? 1 : 0);
	}

	public string ValidatePetMorphRule(AolaPetMorphRule rule)
	{
		if (rule == null || rule.OriginalId <= 0)
		{
			return "原型 ID 无效。";
		}
		if (rule.BackpackId > 0)
		{
			if (rule.OriginalId < 4400 || rule.BackpackId < 4400)
			{
				return "背包动态模型仅支持 ID 大于等于 4400；较旧 ID 使用另一套静态资源格式。";
			}
			if (rule.OriginalId.ToString().Length != rule.BackpackId.ToString().Length)
			{
				return "背包原型 ID 与替换 ID 的位数必须一致，以保持 SWF 类名长度不变。";
			}
		}
		if (rule.PosterId > 0)
		{
			if (!TryGetPosterResourceId(rule.OriginalId, out int originalResourceId))
			{
				return "当前海报映射只识别皮肤 ID 5487 和 5940。";
			}
			if (!TryGetPosterResourceId(rule.PosterId, out int replacementResourceId))
			{
				return "当前海报替换 ID 只支持皮肤 ID 5487 和 5940。";
			}
			if (originalResourceId.ToString().Length != replacementResourceId.ToString().Length)
			{
				return "海报资源类名长度不一致，不能进行安全的等长替换。";
			}
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
		return plan == null ? null : new RemoteSwfResourceRequestHandler(plan, false);
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

	private static RemoteSwfPlan CreatePosterPlan(
		AolaPetMorphRule[] rules,
		Uri requestedUri,
		int requestedResourceId,
		string suffix)
	{
		foreach (AolaPetMorphRule rule in rules)
		{
			if (rule.PosterId <= 0 ||
				!TryGetPosterResourceId(rule.OriginalId, out int originalResourceId) ||
				originalResourceId != requestedResourceId ||
				!TryGetPosterResourceId(rule.PosterId, out int replacementResourceId))
			{
				continue;
			}

			string path = "/play/pet/petskin/background/petskinbackground" +
				replacementResourceId + suffix + ".swf";
			return new RemoteSwfPlan(
				requestedUri.AbsoluteUri,
				BuildRemoteUrl(requestedUri, path, "p-" + originalResourceId + "-" + replacementResourceId),
				"Background" + replacementResourceId,
				"Background" + originalResourceId,
				3,
				1);
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
			if (rule.OriginalId != requestedMovieId || rule.BackpackId <= 0)
			{
				continue;
			}

			int replacementId = rule.BackpackId;
			string path = "/play/peticon/movie/type0/petmovie" + replacementId +
				"/petmovie" + replacementId + "_" + part + suffix + ".swf";
			string marker = "m-" + requestedMovieId + "-" + replacementId + "-" + part;
			return new RemoteSwfPlan(
				requestedUri.AbsoluteUri,
				BuildRemoteUrl(requestedUri, path, marker),
				"PetMovie" + replacementId,
				"PetMovie" + requestedMovieId,
				GetExpectedPetMovieTokenCount(replacementId, part),
				GetPetMovieHdScale(replacementId) / GetPetMovieHdScale(requestedMovieId));
		}
		return null;
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
		if (parts.Length == 4 && parts[0] == "m" &&
			int.TryParse(parts[1], out int originalMovieId) &&
			int.TryParse(parts[2], out int replacementMovieId) &&
			int.TryParse(parts[3], out int markerPart) &&
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
				GetPetMovieHdScale(replacementMovieId) / GetPetMovieHdScale(originalMovieId));
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
				3,
				1);
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

	private static bool TryGetPosterResourceId(int skinId, out int resourceId)
	{
		if (skinId == 5487)
		{
			resourceId = 733;
			return true;
		}
		if (skinId == 5940)
		{
			resourceId = 984;
			return true;
		}
		resourceId = -1;
		return false;
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
			double scaleFactor)
		{
			OriginalUrl = originalUrl;
			RemoteUrl = remoteUrl;
			SourceToken = sourceToken;
			TargetToken = targetToken;
			ExpectedCount = expectedCount;
			ScaleFactor = scaleFactor;
		}

		public string OriginalUrl { get; }
		public string RemoteUrl { get; }
		public string SourceToken { get; }
		public string TargetToken { get; }
		public int ExpectedCount { get; }
		public double ScaleFactor { get; }
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
				_plan.ScaleFactor);
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
			request.AddRange(0, 7);
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
				byte[] header = new byte[8];
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
				if (offset != header.Length || header[0] != 'F' || header[1] != 'W' || header[2] != 'S')
				{
					return false;
				}

				uint declaredLength = BitConverter.ToUInt32(header, 4);
				long responseLength = GetTotalResponseLength(response);
				return declaredLength >= 8 && declaredLength <= MaximumSwfBytes &&
					responseLength == declaredLength;
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
