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
				if (response.ContentLength > request.MaximumResponseBytes)
				{
					return RemoteResourceFetchResult.Reject(
						"fetch.content_length_too_large",
						"Remote Content-Length exceeded the configured bound.",
						statusCode);
				}

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
				if (content.Length == 0)
				{
					return RemoteResourceFetchResult.Reject(
						"fetch.empty",
						"Remote body was empty.",
						statusCode);
				}
				return RemoteResourceFetchResult.Success(
					statusCode,
					response.ContentType,
					content.ToArray());
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
