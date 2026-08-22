using System;

namespace AolaLoader.ResourceInterception.Contracts;

internal interface IResourceResponseTransformer
{
	string Name { get; }

	string InputContract { get; }

	ResourceTransformResult Transform(ResourceTransformInput input);
}

internal sealed class ResourceTransformInput
{
	private readonly byte[] _content;

	public ResourceTransformInput(
		string sourceUrl,
		int httpStatusCode,
		string contentType,
		byte[] content)
	{
		if (!ResourceRequestContext.TryCreateHttpUri(sourceUrl, out _))
		{
			throw new ArgumentException("Source URL must be an absolute HTTP or HTTPS URL.", nameof(sourceUrl));
		}
		if (httpStatusCode < 100 || httpStatusCode > 599)
		{
			throw new ArgumentOutOfRangeException(nameof(httpStatusCode));
		}
		if (content == null)
		{
			throw new ArgumentNullException(nameof(content));
		}

		SourceUrl = sourceUrl;
		HttpStatusCode = httpStatusCode;
		ContentType = contentType ?? string.Empty;
		_content = (byte[])content.Clone();
	}

	public string SourceUrl { get; }

	public int HttpStatusCode { get; }

	public string ContentType { get; }

	public byte[] Content => (byte[])_content.Clone();

	public long ContentLength => _content.LongLength;
}

internal sealed class ResourceTransformResult
{
	private readonly byte[] _content;

	private ResourceTransformResult(
		bool succeeded,
		byte[] content,
		string contentType,
		string rejectionCode,
		string message)
	{
		Succeeded = succeeded;
		_content = content == null ? null : (byte[])content.Clone();
		ContentType = contentType;
		RejectionCode = rejectionCode;
		Message = message;
	}

	public bool Succeeded { get; }

	public byte[] Content => _content == null ? null : (byte[])_content.Clone();

	public string ContentType { get; }

	public string RejectionCode { get; }

	public string Message { get; }

	public static ResourceTransformResult Success(byte[] content, string contentType)
	{
		if (content == null || content.Length == 0)
		{
			throw new ArgumentException("Transformed content is required.", nameof(content));
		}
		if (string.IsNullOrWhiteSpace(contentType))
		{
			throw new ArgumentException("Content type is required.", nameof(contentType));
		}
		return new ResourceTransformResult(true, content, contentType, null, null);
	}

	public static ResourceTransformResult Reject(string rejectionCode, string message)
	{
		if (string.IsNullOrWhiteSpace(rejectionCode))
		{
			throw new ArgumentException("Rejection code is required.", nameof(rejectionCode));
		}
		return new ResourceTransformResult(
			false,
			null,
			null,
			rejectionCode,
			message ?? string.Empty);
	}
}

