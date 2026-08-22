using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace AolaLoader.ResourceInterception.Contracts;

internal sealed class ResourceRequestContext
{
	private readonly IReadOnlyDictionary<string, string> _headers;

	public ResourceRequestContext(
		string originalUrl,
		string method,
		string resourceType,
		IDictionary<string, string> headers = null,
		bool isRewrittenRequest = false,
		bool isFallbackRequest = false,
		string internalPlanKey = null)
	{
		if (!TryCreateHttpUri(originalUrl, out Uri uri))
		{
			throw new ArgumentException("Resource URL must be an absolute HTTP or HTTPS URL.", nameof(originalUrl));
		}
		if (string.IsNullOrWhiteSpace(method))
		{
			throw new ArgumentException("HTTP method is required.", nameof(method));
		}
		if ((isRewrittenRequest || isFallbackRequest) && string.IsNullOrWhiteSpace(internalPlanKey))
		{
			throw new ArgumentException("Internally rewritten requests require a plan key.", nameof(internalPlanKey));
		}

		OriginalUrl = originalUrl;
		Scheme = uri.Scheme.ToLowerInvariant();
		Host = uri.IdnHost.ToLowerInvariant();
		Path = uri.AbsolutePath;
		Query = uri.Query;
		Method = method.Trim().ToUpperInvariant();
		ResourceType = string.IsNullOrWhiteSpace(resourceType) ? string.Empty : resourceType.Trim();
		IsRewrittenRequest = isRewrittenRequest;
		IsFallbackRequest = isFallbackRequest;
		InternalPlanKey = internalPlanKey;

		Dictionary<string, string> copy = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
		if (headers != null)
		{
			foreach (KeyValuePair<string, string> header in headers)
			{
				if (string.IsNullOrWhiteSpace(header.Key))
				{
					throw new ArgumentException("Header names cannot be empty.", nameof(headers));
				}
				copy[header.Key] = header.Value ?? string.Empty;
			}
		}
		_headers = new ReadOnlyDictionary<string, string>(copy);
	}

	public string OriginalUrl { get; }

	public string Scheme { get; }

	public string Host { get; }

	public string Path { get; }

	public string Query { get; }

	public string Method { get; }

	public string ResourceType { get; }

	public IReadOnlyDictionary<string, string> Headers => _headers;

	public bool IsRewrittenRequest { get; }

	public bool IsFallbackRequest { get; }

	public string InternalPlanKey { get; }

	internal static bool TryCreateHttpUri(string value, out Uri uri)
	{
		return Uri.TryCreate(value, UriKind.Absolute, out uri) &&
			(uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) &&
			!string.IsNullOrWhiteSpace(uri.Host);
	}
}

