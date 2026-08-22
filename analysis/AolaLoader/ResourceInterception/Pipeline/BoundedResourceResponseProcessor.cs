using System;
using System.IO;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class BoundedResourceResponseProcessor : IDisposable
{
	private readonly long _maximumBytes;
	private MemoryStream _buffer = new MemoryStream();
	private string _rejectionCode;
	private bool _completed;

	public BoundedResourceResponseProcessor(long maximumBytes)
	{
		if (maximumBytes <= 0 || maximumBytes > int.MaxValue)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumBytes));
		}
		_maximumBytes = maximumBytes;
	}

	public long Length => _buffer?.Length ?? 0;

	public bool IsRejected => _rejectionCode != null;

	public bool TryAppend(byte[] content, int offset, int count)
	{
		ThrowIfCompletedOrDisposed();
		if (content == null)
		{
			throw new ArgumentNullException(nameof(content));
		}
		if (offset < 0 || count < 0 || offset > content.Length - count)
		{
			throw new ArgumentOutOfRangeException(nameof(offset));
		}
		if (_rejectionCode != null)
		{
			return false;
		}
		if (_buffer.Length + count > _maximumBytes)
		{
			_rejectionCode = "response.input_too_large";
			return false;
		}
		_buffer.Write(content, offset, count);
		return true;
	}

	public ResourceTransformResult Complete(
		string sourceUrl,
		int httpStatusCode,
		string contentType,
		string defaultContentType,
		IResourceResponseTransformer transformer)
	{
		ThrowIfCompletedOrDisposed();
		_completed = true;
		if (_rejectionCode != null)
		{
			return ResourceTransformResult.Reject(_rejectionCode, "Response exceeded the configured input bound.");
		}
		if (httpStatusCode < 200 || httpStatusCode > 299)
		{
			return ResourceTransformResult.Reject(
				"response.http_non_success",
				"Remote response status was " + httpStatusCode + ".");
		}
		if (_buffer.Length == 0)
		{
			return ResourceTransformResult.Reject("response.empty", "Remote response was empty.");
		}

		byte[] content = _buffer.ToArray();
		string resolvedContentType = string.IsNullOrWhiteSpace(contentType)
			? defaultContentType
			: contentType;
		if (transformer == null)
		{
			if (string.IsNullOrWhiteSpace(resolvedContentType))
			{
				return ResourceTransformResult.Reject(
					"response.content_type_missing",
					"No response content type was available.");
			}
			return ResourceTransformResult.Success(content, resolvedContentType);
		}

		ResourceTransformResult result;
		try
		{
			result = transformer.Transform(new ResourceTransformInput(
				sourceUrl,
				httpStatusCode,
				resolvedContentType,
				content));
		}
		catch (Exception ex)
		{
			return ResourceTransformResult.Reject(
				"response.transform_exception",
				ex.GetType().Name);
		}
		if (result == null)
		{
			return ResourceTransformResult.Reject(
				"response.transform_invalid",
				"Transformer returned null.");
		}
		if (result.Succeeded && result.Content.LongLength > _maximumBytes)
		{
			return ResourceTransformResult.Reject(
				"response.output_too_large",
				"Transformed response exceeded the configured output bound.");
		}
		return result;
	}

	public void Dispose()
	{
		_completed = true;
		_buffer?.Dispose();
		_buffer = null;
	}

	private void ThrowIfCompletedOrDisposed()
	{
		if (_completed || _buffer == null)
		{
			throw new ObjectDisposedException(nameof(BoundedResourceResponseProcessor));
		}
	}
}
