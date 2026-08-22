using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;

namespace AolaLoader.BrowserHost.Testing;

internal sealed class ManualPageBridge : IPageBridge
{
	private readonly object _syncRoot = new object();
	private PageBridgeAvailability _availability = PageBridgeAvailability.Unknown;
	private bool _disposed;

	public Func<PageBridgeRequest, CancellationToken, Task<PageBridgeResult>> InvokeHandler { get; set; }

	public Func<PageFeatureStatePush, CancellationToken, Task<PageBridgeResult>> PushHandler { get; set; }

	public PageBridgeAvailability Availability
	{
		get
		{
			lock (_syncRoot)
			{
				return _disposed ? PageBridgeAvailability.Closed : _availability;
			}
		}
	}

	public void SetAvailability(PageBridgeAvailability availability)
	{
		if (availability == PageBridgeAvailability.Closed)
		{
			throw new ArgumentException("Dispose the bridge to mark it closed.", nameof(availability));
		}
		lock (_syncRoot)
		{
			ThrowIfDisposed();
			_availability = availability;
		}
	}

	public Task<PageBridgeResult> InvokeAsync(
		PageBridgeRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		return ExecuteAsync(InvokeHandler, request, cancellationToken);
	}

	public Task<PageBridgeResult> PushFeatureStateAsync(
		PageFeatureStatePush state,
		CancellationToken cancellationToken)
	{
		if (state == null)
		{
			throw new ArgumentNullException(nameof(state));
		}
		return ExecuteAsync(PushHandler, state, cancellationToken);
	}

	public void Dispose()
	{
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			InvokeHandler = null;
			PushHandler = null;
		}
	}

	private async Task<PageBridgeResult> ExecuteAsync<T>(
		Func<T, CancellationToken, Task<PageBridgeResult>> handler,
		T request,
		CancellationToken cancellationToken)
	{
		PageBridgeAvailability availability;
		lock (_syncRoot)
		{
			availability = _disposed ? PageBridgeAvailability.Closed : _availability;
		}

		if (cancellationToken.IsCancellationRequested)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.Cancelled, "Bridge call was cancelled.");
		}
		switch (availability)
		{
			case PageBridgeAvailability.Closed:
				return PageBridgeResult.Failure(PageBridgeFailureKind.BrowserClosed, "Browser is closed.");
			case PageBridgeAvailability.PageNotReady:
			case PageBridgeAvailability.Unknown:
				return PageBridgeResult.Failure(PageBridgeFailureKind.PageNotReady, "Page is not ready.");
			case PageBridgeAvailability.BridgeNotInstalled:
				return PageBridgeResult.Failure(PageBridgeFailureKind.BridgeNotInstalled, "Bridge is not installed.");
		}
		if (handler == null)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.InvocationFailed, "No bridge handler is configured.");
		}

		try
		{
			PageBridgeResult result = await handler(request, cancellationToken).ConfigureAwait(false);
			return result ?? PageBridgeResult.Failure(
				PageBridgeFailureKind.InvocationFailed,
				"Bridge handler returned no result.");
		}
		catch (OperationCanceledException)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.Cancelled, "Bridge call was cancelled.");
		}
		catch (Exception ex)
		{
			return PageBridgeResult.Failure(PageBridgeFailureKind.InvocationFailed, ex.Message);
		}
	}

	private void ThrowIfDisposed()
	{
		if (_disposed)
		{
			throw new ObjectDisposedException(nameof(ManualPageBridge));
		}
	}
}

