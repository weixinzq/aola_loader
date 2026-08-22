using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;

namespace AolaLoader.BrowserHost.Testing;

internal sealed class ManualBrowserSession : IBrowserSession
{
	private readonly object _syncRoot = new object();
	private Action<BrowserPageLifecycleEvent> _pageLifecycleChanged;
	private string _currentAddress = string.Empty;
	private bool _closed;

	public Func<BrowserScriptRequest, CancellationToken, Task<BrowserScriptResult>> ScriptHandler { get; set; }

	public int RefreshCount { get; private set; }

	public BrowserRefreshMode LastRefreshMode { get; private set; }

	public string CurrentAddress
	{
		get
		{
			lock (_syncRoot)
			{
				return _currentAddress;
			}
		}
	}

	public bool IsClosed
	{
		get
		{
			lock (_syncRoot)
			{
				return _closed;
			}
		}
	}

	public event Action<BrowserPageLifecycleEvent> PageLifecycleChanged
	{
		add
		{
			lock (_syncRoot)
			{
				ThrowIfClosed();
				_pageLifecycleChanged += value;
			}
		}
		remove
		{
			lock (_syncRoot)
			{
				_pageLifecycleChanged -= value;
			}
		}
	}

	public void Navigate(string address)
	{
		if (!BrowserContractValidation.TryCreateHttpUri(address, out Uri uri))
		{
			throw new ArgumentException("Navigation address must be an absolute HTTP or HTTPS URL.", nameof(address));
		}

		Action<BrowserPageLifecycleEvent> handlers;
		lock (_syncRoot)
		{
			ThrowIfClosed();
			_currentAddress = uri.AbsoluteUri;
			handlers = _pageLifecycleChanged;
		}
		BrowserEventDispatch.InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(
				BrowserPageLifecycleKind.NavigationStarted,
				uri.AbsoluteUri,
				DateTime.UtcNow));
	}

	public void Refresh(BrowserRefreshMode mode)
	{
		lock (_syncRoot)
		{
			ThrowIfClosed();
			RefreshCount++;
			LastRefreshMode = mode;
		}
	}

	public Task<BrowserScriptResult> ExecuteScriptAsync(
		BrowserScriptRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}

		Func<BrowserScriptRequest, CancellationToken, Task<BrowserScriptResult>> handler;
		lock (_syncRoot)
		{
			if (_closed)
			{
				return Task.FromResult(BrowserScriptResult.Failure(
					BrowserScriptFailureKind.BrowserClosed,
					"Browser session is closed."));
			}
			handler = ScriptHandler;
		}
		if (cancellationToken.IsCancellationRequested)
		{
			return Task.FromResult(BrowserScriptResult.Failure(
				BrowserScriptFailureKind.Cancelled,
				"Script execution was cancelled."));
		}
		if (handler == null)
		{
			return Task.FromResult(BrowserScriptResult.Failure(
				BrowserScriptFailureKind.PageNotReady,
				"No script handler is configured."));
		}
		return ExecuteHandlerAsync(handler, request, cancellationToken);
	}

	public void PublishMainFrameReady()
	{
		Publish(BrowserPageLifecycleKind.MainFrameReady, null);
	}

	public void PublishNavigationFailure(string error)
	{
		Publish(BrowserPageLifecycleKind.NavigationFailed, error);
	}

	public void Dispose()
	{
		Action<BrowserPageLifecycleEvent> handlers;
		string address;
		lock (_syncRoot)
		{
			if (_closed)
			{
				return;
			}
			_closed = true;
			address = _currentAddress;
			handlers = _pageLifecycleChanged;
			_pageLifecycleChanged = null;
			ScriptHandler = null;
		}
		BrowserEventDispatch.InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(
				BrowserPageLifecycleKind.Closed,
				address,
				DateTime.UtcNow));
	}

	private void Publish(BrowserPageLifecycleKind kind, string error)
	{
		Action<BrowserPageLifecycleEvent> handlers;
		string address;
		lock (_syncRoot)
		{
			ThrowIfClosed();
			if (string.IsNullOrWhiteSpace(_currentAddress))
			{
				throw new InvalidOperationException("Navigate before publishing page lifecycle events.");
			}
			address = _currentAddress;
			handlers = _pageLifecycleChanged;
		}
		BrowserEventDispatch.InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(kind, address, DateTime.UtcNow, error));
	}

	private static async Task<BrowserScriptResult> ExecuteHandlerAsync(
		Func<BrowserScriptRequest, CancellationToken, Task<BrowserScriptResult>> handler,
		BrowserScriptRequest request,
		CancellationToken cancellationToken)
	{
		try
		{
			BrowserScriptResult result = await handler(request, cancellationToken).ConfigureAwait(false);
			return result ?? BrowserScriptResult.Failure(
				BrowserScriptFailureKind.ExecutionFailed,
				"Script handler returned no result.");
		}
		catch (OperationCanceledException)
		{
			return BrowserScriptResult.Failure(
				BrowserScriptFailureKind.Cancelled,
				"Script execution was cancelled.");
		}
		catch (Exception ex)
		{
			return BrowserScriptResult.Failure(BrowserScriptFailureKind.ExecutionFailed, ex.Message);
		}
	}

	private void ThrowIfClosed()
	{
		if (_closed)
		{
			throw new ObjectDisposedException(nameof(ManualBrowserSession));
		}
	}
}

internal static class BrowserEventDispatch
{
	public static void InvokeSafely<T>(Action<T> handlers, T value)
	{
		if (handlers == null)
		{
			return;
		}
		foreach (Action<T> handler in handlers.GetInvocationList())
		{
			try
			{
				handler(value);
			}
			catch (Exception)
			{
			}
		}
	}
}

