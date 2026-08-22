using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Pipeline;

internal sealed class RemoteResourcePlanExecutor
{
	private static readonly TimeSpan AvailableTimeToLive = TimeSpan.FromMinutes(10);
	private static readonly TimeSpan UnavailableTimeToLive = TimeSpan.FromSeconds(30);
	private readonly IRemoteResourceProbe _probe;
	private readonly IRemoteResourceFetcher _fetcher;

	public RemoteResourcePlanExecutor(IRemoteResourceProbe probe, IRemoteResourceFetcher fetcher)
	{
		_probe = probe ?? throw new ArgumentNullException(nameof(probe));
		_fetcher = fetcher ?? throw new ArgumentNullException(nameof(fetcher));
	}

	public async Task<ResourceTransformResult> ExecuteAsync(
		ResourceInterceptionPlan plan,
		CancellationToken cancellationToken)
	{
		if (plan == null)
		{
			throw new ArgumentNullException(nameof(plan));
		}
		if (plan.Outcome != ResourceInterceptionOutcome.RewriteRemote)
		{
			throw new ArgumentException("Remote execution requires a RewriteRemote plan.", nameof(plan));
		}

		RemoteResourceProbeResult probeResult;
		try
		{
			probeResult = await _probe.ProbeAsync(new RemoteResourceProbeRequest(
				plan.TargetUrl,
				plan.CacheKey,
				plan.DiagnosticKey,
				plan.MaximumResponseBytes,
				AvailableTimeToLive,
				UnavailableTimeToLive), cancellationToken).ConfigureAwait(false);
		}
		catch (OperationCanceledException)
		{
			throw;
		}
		catch (Exception ex)
		{
			return ResourceTransformResult.Reject("remote.probe_exception", ex.GetType().Name);
		}
		if (probeResult == null || !probeResult.Available)
		{
			return ResourceTransformResult.Reject(
				probeResult?.RejectionCode ?? "remote.probe_unavailable",
				probeResult?.Message ?? "Remote probe returned no result.");
		}

		RemoteResourceFetchResult fetchResult;
		try
		{
			fetchResult = await _fetcher.FetchAsync(new RemoteResourceFetchRequest(
				plan.TargetUrl,
				plan.DiagnosticKey,
				plan.MaximumResponseBytes), cancellationToken).ConfigureAwait(false);
		}
		catch (OperationCanceledException)
		{
			throw;
		}
		catch (Exception ex)
		{
			return ResourceTransformResult.Reject("remote.fetch_exception", ex.GetType().Name);
		}
		if (fetchResult == null || !fetchResult.Succeeded)
		{
			return ResourceTransformResult.Reject(
				fetchResult?.RejectionCode ?? "remote.fetch_failed",
				fetchResult?.Message ?? "Remote fetch returned no result.");
		}

		using BoundedResourceResponseProcessor processor =
			new BoundedResourceResponseProcessor(plan.MaximumResponseBytes);
		byte[] content = fetchResult.Content;
		processor.TryAppend(content, 0, content.Length);
		return processor.Complete(
			plan.TargetUrl,
			fetchResult.HttpStatusCode.Value,
			fetchResult.ContentType,
			plan.ContentType,
			plan.Transformer);
	}
}
