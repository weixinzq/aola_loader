using System;
using System.Threading;
using System.Threading.Tasks;

namespace AolaLoader.ResourceInterception.Contracts;

internal interface IRemoteResourceFetcher
{
	Task<RemoteResourceFetchResult> FetchAsync(
		RemoteResourceFetchRequest request,
		CancellationToken cancellationToken);
}

internal sealed class RemoteResourceFetchRequest
{
	public RemoteResourceFetchRequest(string targetUrl, string diagnosticKey, long maximumResponseBytes)
	{
		if (!ResourceRequestContext.TryCreateHttpUri(targetUrl, out _))
		{
			throw new ArgumentException("Fetch URL must be an absolute HTTP or HTTPS URL.", nameof(targetUrl));
		}
		if (string.IsNullOrWhiteSpace(diagnosticKey))
		{
			throw new ArgumentException("Diagnostic key is required.", nameof(diagnosticKey));
		}
		if (maximumResponseBytes <= 0 || maximumResponseBytes > int.MaxValue)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumResponseBytes));
		}
		TargetUrl = targetUrl;
		DiagnosticKey = diagnosticKey;
		MaximumResponseBytes = maximumResponseBytes;
	}

	public string TargetUrl { get; }

	public string DiagnosticKey { get; }

	public long MaximumResponseBytes { get; }
}

internal sealed class RemoteResourceFetchResult
{
	private readonly byte[] _content;

	private RemoteResourceFetchResult(
		bool succeeded,
		int? httpStatusCode,
		string contentType,
		byte[] content,
		string rejectionCode,
		string message)
	{
		Succeeded = succeeded;
		HttpStatusCode = httpStatusCode;
		ContentType = contentType ?? string.Empty;
		_content = content == null ? null : (byte[])content.Clone();
		RejectionCode = rejectionCode;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }

	public int? HttpStatusCode { get; }

	public string ContentType { get; }

	public byte[] Content => _content == null ? null : (byte[])_content.Clone();

	public string RejectionCode { get; }

	public string Message { get; }

	public static RemoteResourceFetchResult Success(int httpStatusCode, string contentType, byte[] content)
	{
		if (httpStatusCode < 200 || httpStatusCode > 299)
		{
			throw new ArgumentOutOfRangeException(nameof(httpStatusCode));
		}
		if (content == null || content.Length == 0)
		{
			throw new ArgumentException("Fetched content is required.", nameof(content));
		}
		return new RemoteResourceFetchResult(true, httpStatusCode, contentType, content, null, null);
	}

	public static RemoteResourceFetchResult Reject(
		string rejectionCode,
		string message,
		int? httpStatusCode = null)
	{
		if (string.IsNullOrWhiteSpace(rejectionCode))
		{
			throw new ArgumentException("Rejection code is required.", nameof(rejectionCode));
		}
		if (httpStatusCode.HasValue && (httpStatusCode.Value < 100 || httpStatusCode.Value > 599))
		{
			throw new ArgumentOutOfRangeException(nameof(httpStatusCode));
		}
		return new RemoteResourceFetchResult(
			false,
			httpStatusCode,
			null,
			null,
			rejectionCode,
			message);
	}
}
