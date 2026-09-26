// 架构角色：一次性捕获目标 SWF 响应的诊断会话，拥有临时 handler/filter 和输出文件生命周期。
// 数据流：匹配的 CEF 响应字节 -> 有界收集/校验 -> 显式保存结果。
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using CefSharp;
using CefSharp.Handler;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.ResourceInterception.Cef;

internal sealed class AolaSwfCaptureSession
{
	private const string EnableMarkerName = "swf-capture.enabled";
	private const int MaximumCapturedBytes = 64 * 1024 * 1024;
	private readonly object _logSync = new object();
	private readonly string _rootDirectory;
	private readonly string _sourceDirectory;
	private readonly string _eventsPath;
	private int _nextRequestId;

	private AolaSwfCaptureSession(string baseDirectory)
	{
		string logsDirectory = Path.Combine(baseDirectory, "logs");
		Directory.CreateDirectory(logsDirectory);
		_rootDirectory = CreateUniqueDirectory(logsDirectory);
		_sourceDirectory = Path.Combine(_rootDirectory, "source");
		Directory.CreateDirectory(_sourceDirectory);
		_eventsPath = Path.Combine(_rootDirectory, "requests.jsonl");

		JObject session = new JObject
		{
			["startedUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["mode"] = "pass-through-swf-response-capture",
			["responseMutation"] = false,
			["cefCachePath"] = Path.Combine(baseDirectory, "cache"),
			["queryValuesRecorded"] = false,
			["maximumCapturedBytes"] = MaximumCapturedBytes
		};
		File.WriteAllText(
			Path.Combine(_rootDirectory, "session.json"),
			session.ToString(Formatting.Indented),
			new UTF8Encoding(false));
	}

	public string RootDirectory => _rootDirectory;

	public static AolaSwfCaptureSession TryStart(string baseDirectory)
	{
		if (string.IsNullOrWhiteSpace(baseDirectory) ||
			!File.Exists(Path.Combine(baseDirectory, EnableMarkerName)))
		{
			return null;
		}
		return new AolaSwfCaptureSession(baseDirectory);
	}

	public static bool IsSwfUrl(string url)
	{
		return Uri.TryCreate(url, UriKind.Absolute, out Uri uri) &&
			uri.AbsolutePath.EndsWith(".swf", StringComparison.OrdinalIgnoreCase);
	}

	public IResourceRequestHandler CreateHandler(IRequest request)
	{
		int requestId = System.Threading.Interlocked.Increment(ref _nextRequestId);
		string url = request.Url;
		Record(new JObject
		{
			["timeUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["requestId"] = requestId,
			["event"] = "Requested",
			["url"] = GetUrlWithoutQuery(url),
			["queryKeys"] = new JArray(GetQueryKeys(url)),
			["querySha256"] = GetQueryHash(url),
			["method"] = request.Method,
			["resourceType"] = request.ResourceType.ToString()
		});
		return new CaptureResourceRequestHandler(this, requestId, url);
	}

	private CaptureResponseFilter CreateFilter(int requestId, string url)
	{
		string requestedName = GetSafeFileName(url);
		string prefix = requestId.ToString("D5", CultureInfo.InvariantCulture) + "-";
		string finalPath = Path.Combine(_sourceDirectory, prefix + requestedName);
		return new CaptureResponseFilter(this, requestId, finalPath, MaximumCapturedBytes);
	}

	private void RecordResponse(int requestId, IResponse response)
	{
		JObject headers = GetSafeResponseHeaders(response?.Headers);
		Record(new JObject
		{
			["timeUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["requestId"] = requestId,
			["event"] = "Response",
			["statusCode"] = response?.StatusCode ?? 0,
			["statusText"] = response?.StatusText ?? string.Empty,
			["mimeType"] = response?.MimeType ?? string.Empty,
			["headers"] = headers,
			["cacheEvidence"] = ClassifyCacheEvidence(headers)
		});
	}

	private void RecordRedirect(int requestId, string newUrl)
	{
		Record(new JObject
		{
			["timeUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["requestId"] = requestId,
			["event"] = "Redirected",
			["url"] = GetUrlWithoutQuery(newUrl),
			["queryKeys"] = new JArray(GetQueryKeys(newUrl)),
			["querySha256"] = GetQueryHash(newUrl)
		});
	}

	private void RecordLoadComplete(
		int requestId,
		UrlRequestStatus status,
		long receivedContentLength)
	{
		Record(new JObject
		{
			["timeUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["requestId"] = requestId,
			["event"] = "LoadComplete",
			["status"] = status.ToString(),
			["receivedContentLength"] = receivedContentLength
		});
	}

	private void RecordSaved(
		int requestId,
		string finalPath,
		long size,
		string sha256,
		string signature,
		bool complete,
		string error)
	{
		Record(new JObject
		{
			["timeUtc"] = DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture),
			["requestId"] = requestId,
			["event"] = "BodySaved",
			["relativePath"] = "source/" + Path.GetFileName(finalPath),
			["size"] = size,
			["sha256"] = sha256 ?? string.Empty,
			["signature"] = signature ?? string.Empty,
			["complete"] = complete,
			["error"] = error ?? string.Empty
		});
	}

	private void Record(JObject record)
	{
		string line = record.ToString(Formatting.None);
		lock (_logSync)
		{
			File.AppendAllText(_eventsPath, line + Environment.NewLine, new UTF8Encoding(false));
		}
	}

	private static string CreateUniqueDirectory(string logsDirectory)
	{
		string stem = "swf-capture-" +
			DateTime.Now.ToString("yyyyMMdd-HHmmssfff", CultureInfo.InvariantCulture);
		string path = Path.Combine(logsDirectory, stem);
		for (int suffix = 1; Directory.Exists(path); suffix++)
		{
			path = Path.Combine(logsDirectory, stem + "-" +
				suffix.ToString(CultureInfo.InvariantCulture));
		}
		Directory.CreateDirectory(path);
		return path;
	}

	private static string GetSafeFileName(string url)
	{
		string name = Uri.TryCreate(url, UriKind.Absolute, out Uri uri)
			? Path.GetFileName(uri.AbsolutePath)
			: "resource.swf";
		if (string.IsNullOrWhiteSpace(name))
		{
			name = "resource.swf";
		}
		char[] invalid = Path.GetInvalidFileNameChars();
		name = new string(name.Select(character => invalid.Contains(character) ? '_' : character).ToArray());
		if (!name.EndsWith(".swf", StringComparison.OrdinalIgnoreCase))
		{
			name += ".swf";
		}
		return name.Length <= 140 ? name : name.Substring(name.Length - 140);
	}

	private static string GetUrlWithoutQuery(string url)
	{
		return Uri.TryCreate(url, UriKind.Absolute, out Uri uri)
			? uri.GetLeftPart(UriPartial.Path)
			: string.Empty;
	}

	private static IEnumerable<string> GetQueryKeys(string url)
	{
		if (!Uri.TryCreate(url, UriKind.Absolute, out Uri uri) ||
			string.IsNullOrEmpty(uri.Query))
		{
			return Enumerable.Empty<string>();
		}
		return uri.Query.TrimStart('?')
			.Split(new[] { '&' }, StringSplitOptions.RemoveEmptyEntries)
			.Select(item => item.Split(new[] { '=' }, 2)[0])
			.Where(item => !string.IsNullOrWhiteSpace(item))
			.Select(Uri.UnescapeDataString)
			.Distinct(StringComparer.OrdinalIgnoreCase)
			.OrderBy(item => item, StringComparer.OrdinalIgnoreCase)
			.ToArray();
	}

	private static string GetQueryHash(string url)
	{
		if (!Uri.TryCreate(url, UriKind.Absolute, out Uri uri) ||
			string.IsNullOrEmpty(uri.Query))
		{
			return string.Empty;
		}
		using SHA256 sha256 = SHA256.Create();
		return ToHex(sha256.ComputeHash(Encoding.UTF8.GetBytes(uri.Query)));
	}

	private static JObject GetSafeResponseHeaders(NameValueCollection headers)
	{
		JObject result = new JObject();
		if (headers == null)
		{
			return result;
		}
		HashSet<string> allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
		{
			"Age", "Cache-Control", "CF-Cache-Status", "Content-Length", "Content-Type",
			"ETag", "Expires", "Last-Modified", "Server", "Via", "X-Cache", "X-Cache-Hits"
		};
		foreach (string key in headers.AllKeys)
		{
			if (!string.IsNullOrWhiteSpace(key) && allowed.Contains(key))
			{
				result[key] = headers[key] ?? string.Empty;
			}
		}
		return result;
	}

	private static string ClassifyCacheEvidence(JObject headers)
	{
		string combined = string.Join(" ", headers.Properties().Select(item =>
			item.Name + "=" + item.Value));
		if (combined.IndexOf("HIT", StringComparison.OrdinalIgnoreCase) >= 0 ||
			long.TryParse((string)headers["Age"], NumberStyles.Integer,
				CultureInfo.InvariantCulture, out long age) && age > 0)
		{
			return "response-header-cache-hit";
		}
		return "cef-cache-state-not-exposed";
	}

	private static string ToHex(byte[] bytes)
	{
		return BitConverter.ToString(bytes).Replace("-", string.Empty).ToLowerInvariant();
	}

	private sealed class CaptureResourceRequestHandler : ResourceRequestHandler
	{
		private readonly AolaSwfCaptureSession _session;
		private readonly int _requestId;
		private readonly string _url;

		public CaptureResourceRequestHandler(AolaSwfCaptureSession session, int requestId, string url)
		{
			_session = session;
			_requestId = requestId;
			_url = url;
		}

		protected override bool OnResourceResponse(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response)
		{
			_session.RecordResponse(_requestId, response);
			return false;
		}

		protected override IResponseFilter GetResourceResponseFilter(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response)
		{
			return _session.CreateFilter(_requestId, _url);
		}

		protected override void OnResourceRedirect(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response,
			ref string newUrl)
		{
			_session.RecordRedirect(_requestId, newUrl);
		}

		protected override void OnResourceLoadComplete(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IResponse response,
			UrlRequestStatus status,
			long receivedContentLength)
		{
			_session.RecordLoadComplete(_requestId, status, receivedContentLength);
		}
	}

	private sealed class CaptureResponseFilter : IResponseFilter
	{
		private readonly AolaSwfCaptureSession _session;
		private readonly int _requestId;
		private readonly string _finalPath;
		private readonly string _partialPath;
		private readonly int _maximumBytes;
		private FileStream _stream;
		private bool _disposed;
		private bool _overflowed;

		public CaptureResponseFilter(
			AolaSwfCaptureSession session,
			int requestId,
			string finalPath,
			int maximumBytes)
		{
			_session = session;
			_requestId = requestId;
			_finalPath = finalPath;
			_partialPath = finalPath + ".partial";
			_maximumBytes = maximumBytes;
		}

		public bool InitFilter()
		{
			_stream = new FileStream(
				_partialPath,
				FileMode.CreateNew,
				FileAccess.Write,
				FileShare.Read);
			return true;
		}

		public FilterStatus Filter(
			Stream dataIn,
			out long dataInRead,
			Stream dataOut,
			out long dataOutWritten)
		{
			dataInRead = 0;
			dataOutWritten = 0;
			if (dataIn == null)
			{
				return FilterStatus.Done;
			}

			long available = dataIn.Length - dataIn.Position;
			long capacity = dataOut.Length - dataOut.Position;
			int count = (int)Math.Min(Math.Min(available, capacity), 81920);
			if (count <= 0)
			{
				return FilterStatus.NeedMoreData;
			}

			byte[] buffer = new byte[count];
			int read = dataIn.Read(buffer, 0, count);
			if (read <= 0)
			{
				return FilterStatus.NeedMoreData;
			}
			dataOut.Write(buffer, 0, read);
			dataInRead = read;
			dataOutWritten = read;
			if (!_overflowed && _stream.Length + read <= _maximumBytes)
			{
				_stream.Write(buffer, 0, read);
			}
			else
			{
				_overflowed = true;
			}

			return dataIn.Position < dataIn.Length
				? FilterStatus.NeedMoreData
				: FilterStatus.Done;
		}

		public void Dispose()
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			long size = _stream?.Length ?? 0;
			_stream?.Dispose();
			_stream = null;

			string error = null;
			string sha256 = null;
			string signature = null;
			bool complete = false;
			try
			{
				if (_overflowed)
				{
					error = "Capture exceeded the configured byte limit.";
				}
				else
				{
					byte[] header = new byte[3];
					using (FileStream input = File.OpenRead(_partialPath))
					{
						input.Read(header, 0, header.Length);
						input.Position = 0;
						using SHA256 hash = SHA256.Create();
						sha256 = ToHex(hash.ComputeHash(input));
					}
					signature = Encoding.ASCII.GetString(header);
					complete = signature == "FWS" || signature == "CWS" || signature == "ZWS";
					if (!complete)
					{
						error = "Response body is not a recognized SWF signature.";
					}
				}
				File.Move(_partialPath, _finalPath);
			}
			catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException)
			{
				error = ex.Message;
			}
			_session.RecordSaved(
				_requestId,
				File.Exists(_finalPath) ? _finalPath : _partialPath,
				size,
				sha256,
				signature,
				complete,
				error);
		}
	}
}
