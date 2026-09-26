// 架构角色：为 IRemoteResourceProbe 增加按 key 和有效期缓存，减少规则预检的重复网络访问。
// 数据流：probe request -> cache hit 或 inner probe -> CacheEntry/result。
using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class CachingRemoteResourceProbe : IRemoteResourceProbe
{
	private readonly IRemoteResourceProbe _inner;
	private readonly Func<DateTime> _utcNow;
	private readonly ConcurrentDictionary<string, CacheEntry> _cache =
		new ConcurrentDictionary<string, CacheEntry>(StringComparer.Ordinal);

	public CachingRemoteResourceProbe(IRemoteResourceProbe inner, Func<DateTime> utcNow = null)
	{
		_inner = inner ?? throw new ArgumentNullException(nameof(inner));
		_utcNow = utcNow ?? (() => DateTime.UtcNow);
	}

	public async Task<RemoteResourceProbeResult> ProbeAsync(
		RemoteResourceProbeRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		cancellationToken.ThrowIfCancellationRequested();
		string key = request.TargetUrl + "\n" + request.CacheKey + "\n" + request.MaximumResponseBytes;
		DateTime now = _utcNow();
		if (_cache.TryGetValue(key, out CacheEntry cached))
		{
			if (cached.ExpiresUtc > now)
			{
				return cached.Result;
			}
			_cache.TryRemove(key, out _);
		}

		RemoteResourceProbeResult result = await _inner.ProbeAsync(request, cancellationToken)
			.ConfigureAwait(false);
		if (result == null)
		{
			result = RemoteResourceProbeResult.Reject(
				"probe.invalid_result",
				"Remote probe returned no result.");
		}
		TimeSpan ttl = result.Available
			? request.AvailableTimeToLive
			: request.UnavailableTimeToLive;
		_cache[key] = new CacheEntry(result, now + ttl);
		return result;
	}

	private sealed class CacheEntry
	{
		public CacheEntry(RemoteResourceProbeResult result, DateTime expiresUtc)
		{
			Result = result;
			ExpiresUtc = expiresUtc;
		}

		public RemoteResourceProbeResult Result { get; }

		public DateTime ExpiresUtc { get; }
	}
}
