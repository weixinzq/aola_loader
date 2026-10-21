// 架构角色：IRemoteResourceFetcher 的 HTTP 实现，负责状态、长度上限和响应元数据校验。
// 数据流：fetch request -> HttpWebRequest -> 有界 bytes/result。
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class HttpRemoteResourceFetcher : IRemoteResourceFetcher
{
	private readonly int _timeoutMilliseconds;

	public HttpRemoteResourceFetcher(int timeoutMilliseconds = 10000)
	{
		if (timeoutMilliseconds <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(timeoutMilliseconds));
		}
		_timeoutMilliseconds = timeoutMilliseconds;
	}

	public async Task<RemoteResourceFetchResult> FetchAsync(
		RemoteResourceFetchRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}

		HttpWebRequest webRequest = (HttpWebRequest)WebRequest.Create(request.TargetUrl);
		webRequest.Method = "GET";
		webRequest.AllowAutoRedirect = true;
		webRequest.AutomaticDecompression = DecompressionMethods.None;
		webRequest.Timeout = _timeoutMilliseconds;
		webRequest.ReadWriteTimeout = _timeoutMilliseconds;
		webRequest.UserAgent = "AolaLoader/4.0";

		using (cancellationToken.Register(webRequest.Abort))
		{
			try
			{
				using HttpWebResponse response = (HttpWebResponse)await webRequest.GetResponseAsync()
					.ConfigureAwait(false);
				int statusCode = (int)response.StatusCode;
				if (statusCode < 200 || statusCode > 299)
				{
					return RemoteResourceFetchResult.Reject(
						"fetch.http_non_success",
						"Remote resource returned status " + statusCode + ".",
						statusCode);
				}
				long contentLength = response.ContentLength;
				if (contentLength > request.MaximumResponseBytes)
				{
					return RemoteResourceFetchResult.Reject(
						"fetch.content_length_too_large",
						"Remote Content-Length exceeded the configured bound.",
						statusCode);
				}

				byte[] body;
				if (contentLength > 0)
				{
					// Content-Length 已知且在上限内时按精确长度一次分配并读满。
					body = new byte[(int)contentLength];
					using Stream exactStream = response.GetResponseStream();
					int readTotal = 0;
					while (exactStream != null && readTotal < body.Length)
					{
						int read = await exactStream.ReadAsync(
							body,
							readTotal,
							body.Length - readTotal,
							cancellationToken).ConfigureAwait(false);
						if (read <= 0)
						{
							break;
						}
						readTotal += read;
					}
					if (readTotal < body.Length)
					{
						// 声明长度与实际 body 不符（提前 EOF）时收缩到已读长度，保持原 body 语义。
						Array.Resize(ref body, readTotal);
					}
				}
				else
				{
					using MemoryStream content = new MemoryStream();
					using Stream stream = response.GetResponseStream();
					byte[] buffer = new byte[81920];
					while (stream != null)
					{
						int read = await stream.ReadAsync(buffer, 0, buffer.Length, cancellationToken)
							.ConfigureAwait(false);
						if (read <= 0)
						{
							break;
						}
						if (content.Length + read > request.MaximumResponseBytes)
						{
							return RemoteResourceFetchResult.Reject(
								"fetch.body_too_large",
								"Remote body exceeded the configured bound.",
								statusCode);
						}
						content.Write(buffer, 0, read);
					}
					body = content.ToArray();
				}
				if (body.Length == 0)
				{
					return RemoteResourceFetchResult.Reject(
						"fetch.empty",
						"Remote body was empty.",
						statusCode);
				}
				return RemoteResourceFetchResult.SuccessOwned(
					statusCode,
					response.ContentType,
					body);
			}
			catch (OperationCanceledException)
			{
				throw;
			}
			catch (WebException ex) when (cancellationToken.IsCancellationRequested)
			{
				throw new OperationCanceledException("Remote fetch was cancelled.", ex, cancellationToken);
			}
			catch (WebException ex)
			{
				int? statusCode = (ex.Response as HttpWebResponse) == null
					? (int?)null
					: (int)((HttpWebResponse)ex.Response).StatusCode;
				return RemoteResourceFetchResult.Reject(
					statusCode.HasValue ? "fetch.http_non_success" : "fetch.network_error",
					ex.Status.ToString(),
					statusCode);
			}
			catch (IOException ex)
			{
				return RemoteResourceFetchResult.Reject("fetch.read_error", ex.GetType().Name);
			}
		}
	}
}
