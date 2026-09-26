// 架构角色：规则评估的判别联合模型，表达 PassThrough、LocalResponse、RewriteRemote 等结果。
// 数据流：feature rule -> pipeline/CEF adapter；计划携带必要数据而不执行副作用。
using System;

namespace AolaLoader.ResourceInterception.Contracts;

internal enum ResourceInterceptionOutcome
{
	PassThrough,
	LocalResponse,
	RewriteRemote
}

internal sealed class ResourceInterceptionPlan
{
	private readonly byte[] _localContent;

	private ResourceInterceptionPlan(
		ResourceInterceptionOutcome outcome,
		string originalUrl,
		string targetUrl,
		byte[] localContent,
		string contentType,
		IResourceResponseTransformer transformer,
		string fallbackUrl,
		string cacheKey,
		string diagnosticKey,
		long maximumResponseBytes)
	{
		Outcome = outcome;
		OriginalUrl = originalUrl;
		TargetUrl = targetUrl;
		_localContent = localContent == null ? null : (byte[])localContent.Clone();
		ContentType = contentType;
		Transformer = transformer;
		FallbackUrl = fallbackUrl;
		CacheKey = cacheKey;
		DiagnosticKey = diagnosticKey;
		MaximumResponseBytes = maximumResponseBytes;
	}

	public ResourceInterceptionOutcome Outcome { get; }

	public string OriginalUrl { get; }

	public string TargetUrl { get; }

	public byte[] LocalContent => _localContent == null ? null : (byte[])_localContent.Clone();

	public string ContentType { get; }

	public IResourceResponseTransformer Transformer { get; }

	public string FallbackUrl { get; }

	public string CacheKey { get; }

	public string DiagnosticKey { get; }

	public long MaximumResponseBytes { get; }

	public static ResourceInterceptionPlan PassThrough(string originalUrl)
	{
		ValidateUrl(originalUrl, nameof(originalUrl));
		return new ResourceInterceptionPlan(
			ResourceInterceptionOutcome.PassThrough,
			originalUrl,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			0);
	}

	public static ResourceInterceptionPlan LocalResponse(
		string originalUrl,
		byte[] content,
		string contentType,
		string cacheKey,
		string diagnosticKey)
	{
		ValidateUrl(originalUrl, nameof(originalUrl));
		if (content == null || content.Length == 0)
		{
			throw new ArgumentException("Local response content is required.", nameof(content));
		}
		ValidateRequired(contentType, nameof(contentType));
		ValidateRequired(cacheKey, nameof(cacheKey));
		ValidateRequired(diagnosticKey, nameof(diagnosticKey));

		return new ResourceInterceptionPlan(
			ResourceInterceptionOutcome.LocalResponse,
			originalUrl,
			null,
			content,
			contentType,
			null,
			null,
			cacheKey,
			diagnosticKey,
			content.LongLength);
	}

	public static ResourceInterceptionPlan RewriteRemote(
		string originalUrl,
		string targetUrl,
		string contentType,
		IResourceResponseTransformer transformer,
		string fallbackUrl,
		string cacheKey,
		string diagnosticKey,
		long maximumResponseBytes)
	{
		ValidateUrl(originalUrl, nameof(originalUrl));
		ValidateUrl(targetUrl, nameof(targetUrl));
		if (!string.IsNullOrWhiteSpace(fallbackUrl))
		{
			ValidateUrl(fallbackUrl, nameof(fallbackUrl));
		}
		ValidateRequired(cacheKey, nameof(cacheKey));
		ValidateRequired(diagnosticKey, nameof(diagnosticKey));
		if (maximumResponseBytes <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumResponseBytes));
		}

		return new ResourceInterceptionPlan(
			ResourceInterceptionOutcome.RewriteRemote,
			originalUrl,
			targetUrl,
			null,
			contentType,
			transformer,
			fallbackUrl,
			cacheKey,
			diagnosticKey,
			maximumResponseBytes);
	}

	private static void ValidateUrl(string value, string parameterName)
	{
		if (!ResourceRequestContext.TryCreateHttpUri(value, out _))
		{
			throw new ArgumentException("Resource URL must be an absolute HTTP or HTTPS URL.", parameterName);
		}
	}

	private static void ValidateRequired(string value, string parameterName)
	{
		if (string.IsNullOrWhiteSpace(value))
		{
			throw new ArgumentException("Value is required.", parameterName);
		}
	}
}

