using System;
using System.Threading;
using System.Threading.Tasks;

namespace AolaLoader.ResourceInterception.Contracts;

internal interface IRemoteResourceProbe
{
	Task<RemoteResourceProbeResult> ProbeAsync(
		RemoteResourceProbeRequest request,
		CancellationToken cancellationToken);
}

internal sealed class RemoteResourceProbeRequest
{
	public RemoteResourceProbeRequest(
		string targetUrl,
		string cacheKey,
		string diagnosticKey,
		long maximumResponseBytes,
		TimeSpan availableTimeToLive,
		TimeSpan unavailableTimeToLive)
	{
		if (!ResourceRequestContext.TryCreateHttpUri(targetUrl, out _))
		{
			throw new ArgumentException("Probe URL must be an absolute HTTP or HTTPS URL.", nameof(targetUrl));
		}
		if (string.IsNullOrWhiteSpace(cacheKey))
		{
			throw new ArgumentException("Cache key is required.", nameof(cacheKey));
		}
		if (string.IsNullOrWhiteSpace(diagnosticKey))
		{
			throw new ArgumentException("Diagnostic key is required.", nameof(diagnosticKey));
		}
		if (maximumResponseBytes <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumResponseBytes));
		}
		if (availableTimeToLive <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(availableTimeToLive));
		}
		if (unavailableTimeToLive <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(unavailableTimeToLive));
		}

		TargetUrl = targetUrl;
		CacheKey = cacheKey;
		DiagnosticKey = diagnosticKey;
		MaximumResponseBytes = maximumResponseBytes;
		AvailableTimeToLive = availableTimeToLive;
		UnavailableTimeToLive = unavailableTimeToLive;
	}

	public string TargetUrl { get; }

	public string CacheKey { get; }

	public string DiagnosticKey { get; }

	public long MaximumResponseBytes { get; }

	public TimeSpan AvailableTimeToLive { get; }

	public TimeSpan UnavailableTimeToLive { get; }
}

internal sealed class RemoteResourceProbeResult
{
	private RemoteResourceProbeResult(
		bool available,
		int? httpStatusCode,
		long? contentLength,
		string rejectionCode,
		string message)
	{
		Available = available;
		HttpStatusCode = httpStatusCode;
		ContentLength = contentLength;
		RejectionCode = rejectionCode;
		Message = message;
	}

	public bool Available { get; }

	public int? HttpStatusCode { get; }

	public long? ContentLength { get; }

	public string RejectionCode { get; }

	public string Message { get; }

	public static RemoteResourceProbeResult Success(int httpStatusCode, long? contentLength)
	{
		if (httpStatusCode < 200 || httpStatusCode > 299)
		{
			throw new ArgumentOutOfRangeException(nameof(httpStatusCode));
		}
		if (contentLength < 0)
		{
			throw new ArgumentOutOfRangeException(nameof(contentLength));
		}
		return new RemoteResourceProbeResult(true, httpStatusCode, contentLength, null, null);
	}

	public static RemoteResourceProbeResult Reject(
		string rejectionCode,
		string message,
		int? httpStatusCode = null,
		long? contentLength = null)
	{
		if (string.IsNullOrWhiteSpace(rejectionCode))
		{
			throw new ArgumentException("Rejection code is required.", nameof(rejectionCode));
		}
		if (httpStatusCode.HasValue && (httpStatusCode.Value < 100 || httpStatusCode.Value > 599))
		{
			throw new ArgumentOutOfRangeException(nameof(httpStatusCode));
		}
		if (contentLength < 0)
		{
			throw new ArgumentOutOfRangeException(nameof(contentLength));
		}
		return new RemoteResourceProbeResult(
			false,
			httpStatusCode,
			contentLength,
			rejectionCode,
			message ?? string.Empty);
	}
}

