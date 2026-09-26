// 架构角色：面向 SWF 的 HTTP 探测实现，通过小范围请求确认远端长度和头部身份。
// 数据流：probe request -> HTTP metadata/prefix -> RemoteResourceProbeResult。
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class HttpSwfRemoteResourceProbe : IRemoteResourceProbe
{
	private readonly int _timeoutMilliseconds;

	public HttpSwfRemoteResourceProbe(int timeoutMilliseconds = 5000)
	{
		if (timeoutMilliseconds <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(timeoutMilliseconds));
		}
		_timeoutMilliseconds = timeoutMilliseconds;
	}

	public async Task<RemoteResourceProbeResult> ProbeAsync(
		RemoteResourceProbeRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}

		HttpWebRequest webRequest = (HttpWebRequest)WebRequest.Create(request.TargetUrl);
		webRequest.Method = "GET";
		webRequest.AddRange(0, 16);
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
				if (response.StatusCode != HttpStatusCode.PartialContent &&
					response.StatusCode != HttpStatusCode.OK)
				{
					return RemoteResourceProbeResult.Reject(
						"probe.http_non_success",
						"Remote SWF returned status " + statusCode + ".",
						statusCode,
						response.ContentLength);
				}

				byte[] header = new byte[17];
				int offset = 0;
				using Stream stream = response.GetResponseStream();
				while (stream != null && offset < header.Length)
				{
					int read = await stream.ReadAsync(
						header,
						offset,
						header.Length - offset,
						cancellationToken).ConfigureAwait(false);
					if (read <= 0)
					{
						break;
					}
					offset += read;
				}
				long responseLength = GetTotalResponseLength(response);
				if (!SwfResponseHeaderValidator.IsSupported(
					header,
					offset,
					responseLength,
					request.MaximumResponseBytes))
				{
					return RemoteResourceProbeResult.Reject(
						"probe.swf_header_rejected",
						"Remote resource did not satisfy the bounded SWF header contract.",
						statusCode,
						responseLength);
				}
				return RemoteResourceProbeResult.Success(statusCode, responseLength);
			}
			catch (OperationCanceledException)
			{
				throw;
			}
			catch (WebException ex) when (cancellationToken.IsCancellationRequested)
			{
				throw new OperationCanceledException("Remote SWF probe was cancelled.", ex, cancellationToken);
			}
			catch (WebException ex)
			{
				return RemoteResourceProbeResult.Reject("probe.network_error", ex.Status.ToString());
			}
			catch (IOException ex)
			{
				return RemoteResourceProbeResult.Reject("probe.read_error", ex.GetType().Name);
			}
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
}
