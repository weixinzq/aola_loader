using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using CefSharp;
using CefSharp.WinForms;
using Newtonsoft.Json.Linq;

namespace AolaLoader.BrowserHost;

/// <summary>
/// CefSharp production adapter for IBrowserSession. It wraps a ChromiumWebBrowser,
/// owns page lifecycle translation and script execution; Dispose detaches events
/// but does not dispose the underlying browser.
/// </summary>
internal sealed class AolaBrowserSession : IBrowserSession
{
	private readonly object _syncRoot = new object();
	private readonly ChromiumWebBrowser _browser;
	private Action<BrowserPageLifecycleEvent> _pageLifecycleChanged;
	private string _currentAddress;
	private bool _closed;

	public AolaBrowserSession(ChromiumWebBrowser browser)
	{
		_browser = browser ?? throw new ArgumentNullException(nameof(browser));
		_currentAddress = browser.Address;
		_browser.AddressChanged += OnAddressChanged;
		_browser.FrameLoadEnd += OnFrameLoadEnd;
		_browser.LoadError += OnLoadError;
	}

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
		lock (_syncRoot)
		{
			ThrowIfClosed();
		}
		_browser.Load(uri.AbsoluteUri);
	}

	public void Refresh(BrowserRefreshMode mode)
	{
		lock (_syncRoot)
		{
			ThrowIfClosed();
		}
		if (mode == BrowserRefreshMode.IgnoreCache)
		{
			_browser.Reload(true);
		}
		else
		{
			_browser.Reload();
		}
	}

	public async Task<BrowserScriptResult> ExecuteScriptAsync(
		BrowserScriptRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		lock (_syncRoot)
		{
			if (_closed)
			{
				return BrowserScriptResult.Failure(
					BrowserScriptFailureKind.BrowserClosed,
					"浏览器会话已关闭。");
			}
		}
		if (cancellationToken.IsCancellationRequested)
		{
			return BrowserScriptResult.Failure(
				BrowserScriptFailureKind.Cancelled,
				"脚本执行已取消。");
		}

		try
		{
			IFrame frame = _browser.GetMainFrame();
			if (frame == null || !frame.IsValid)
			{
				return BrowserScriptResult.Failure(
					BrowserScriptFailureKind.PageNotReady,
					"浏览器主框架尚未就绪。");
			}

			using (CancellationTokenSource timeoutSource =
				CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
			{
				Task<JavascriptResponse> evaluation = frame.EvaluateScriptAsync(request.Script);
				Task delay = Task.Delay(request.Timeout, timeoutSource.Token);
				Task first = await Task.WhenAny(evaluation, delay).ConfigureAwait(false);
				if (first == delay)
				{
					return timeoutSource.IsCancellationRequested && !cancellationToken.IsCancellationRequested
						? BrowserScriptResult.Failure(
							BrowserScriptFailureKind.Timeout,
							"脚本执行超时。")
						: BrowserScriptResult.Failure(
							BrowserScriptFailureKind.Cancelled,
							"脚本执行已取消。");
				}

				JavascriptResponse response = await evaluation.ConfigureAwait(false);
				if (!response.Success)
				{
					return BrowserScriptResult.Failure(
						BrowserScriptFailureKind.ExecutionFailed,
						response.Message ?? "脚本执行失败。");
				}
				return BrowserScriptResult.Success(
					response.Result == null ? null : JToken.FromObject(response.Result));
			}
		}
		catch (OperationCanceledException)
		{
			return BrowserScriptResult.Failure(
				BrowserScriptFailureKind.Cancelled,
				"脚本执行已取消。");
		}
		catch (ObjectDisposedException ex)
		{
			return BrowserScriptResult.Failure(BrowserScriptFailureKind.BrowserClosed, ex.Message);
		}
		catch (Exception ex)
		{
			return BrowserScriptResult.Failure(BrowserScriptFailureKind.ExecutionFailed, ex.Message);
		}
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
		}
		_browser.AddressChanged -= OnAddressChanged;
		_browser.FrameLoadEnd -= OnFrameLoadEnd;
		_browser.LoadError -= OnLoadError;
		InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(BrowserPageLifecycleKind.Closed, address, DateTime.UtcNow));
	}

	private void OnAddressChanged(object sender, AddressChangedEventArgs e)
	{
		Action<BrowserPageLifecycleEvent> handlers;
		lock (_syncRoot)
		{
			if (_closed)
			{
				return;
			}
			_currentAddress = e.Address;
			handlers = _pageLifecycleChanged;
		}
		InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(
				BrowserPageLifecycleKind.NavigationStarted,
				e.Address,
				DateTime.UtcNow));
	}

	private void OnFrameLoadEnd(object sender, FrameLoadEndEventArgs e)
	{
		if (!e.Frame.IsMain)
		{
			return;
		}
		Action<BrowserPageLifecycleEvent> handlers;
		string address;
		lock (_syncRoot)
		{
			if (_closed)
			{
				return;
			}
			address = _currentAddress;
			handlers = _pageLifecycleChanged;
		}
		InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(
				BrowserPageLifecycleKind.MainFrameReady,
				address,
				DateTime.UtcNow));
	}

	private void OnLoadError(object sender, LoadErrorEventArgs e)
	{
		if (e.ErrorCode == CefErrorCode.Aborted)
		{
			return;
		}
		Action<BrowserPageLifecycleEvent> handlers;
		string address;
		lock (_syncRoot)
		{
			if (_closed)
			{
				return;
			}
			address = _currentAddress;
			handlers = _pageLifecycleChanged;
		}
		InvokeSafely(
			handlers,
			new BrowserPageLifecycleEvent(
				BrowserPageLifecycleKind.NavigationFailed,
				address,
				DateTime.UtcNow,
				e.ErrorText));
	}

	private void ThrowIfClosed()
	{
		if (_closed)
		{
			throw new ObjectDisposedException(nameof(AolaBrowserSession));
		}
	}

	private static void InvokeSafely(Action<BrowserPageLifecycleEvent> handlers, BrowserPageLifecycleEvent value)
	{
		if (handlers == null)
		{
			return;
		}
		foreach (Action<BrowserPageLifecycleEvent> handler in handlers.GetInvocationList())
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
