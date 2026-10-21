// 架构角色：定义响应变换端口及输入输出，隔离 SWF 处理算法与 CEF 流式 API。
// 数据流：原响应 bytes/metadata -> transformer -> 新 bytes/headers 或失败关闭。
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

	internal byte[] ContentUnsafe => _content;

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
		string message,
		bool ownContent = false)
	{
		Succeeded = succeeded;
		_content = content == null || ownContent ? content : (byte[])content.Clone();
		ContentType = contentType;
		RejectionCode = rejectionCode;
		Message = message;
	}

	public bool Succeeded { get; }

	public byte[] Content => _content == null ? null : (byte[])_content.Clone();

	internal byte[] ContentUnsafe => _content;

	internal long ContentLength => _content == null ? 0L : _content.LongLength;

	public string ContentType { get; }

	public string RejectionCode { get; }

	public string Message { get; }

	public static ResourceTransformResult Success(byte[] content, string contentType)
	{
		ValidateSuccess(content, contentType);
		return new ResourceTransformResult(true, content, contentType, null, null);
	}

	// 仅供新建且不再被调用方复用的输出数组使用，结果不复制 content。
	internal static ResourceTransformResult SuccessOwned(byte[] content, string contentType)
	{
		ValidateSuccess(content, contentType);
		return new ResourceTransformResult(true, content, contentType, null, null, ownContent: true);
	}

	private static void ValidateSuccess(byte[] content, string contentType)
	{
		if (content == null || content.Length == 0)
		{
			throw new ArgumentException("Transformed content is required.", nameof(content));
		}
		if (string.IsNullOrWhiteSpace(contentType))
		{
			throw new ArgumentException("Content type is required.", nameof(contentType));
		}
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

