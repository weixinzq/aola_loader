using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using CefSharp.Handler;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;

namespace AolaLoader.ResourceInterception.Cef;

internal sealed class CefResourceRuleAdapter
{
	private readonly ResourceRulePipeline _pipeline;
	private readonly RemoteResourcePlanExecutor _remoteExecutor;

	public CefResourceRuleAdapter(
		ResourceRulePipeline pipeline,
		RemoteResourcePlanExecutor remoteExecutor = null)
	{
		_pipeline = pipeline ?? throw new ArgumentNullException(nameof(pipeline));
		_remoteExecutor = remoteExecutor ?? new RemoteResourcePlanExecutor(
			new CachingRemoteResourceProbe(new HttpSwfRemoteResourceProbe()),
			new HttpRemoteResourceFetcher());
	}

	public IResourceRequestHandler GetResourceRequestHandler(
		IRequest request,
		ref bool disableDefaultHandling)
	{
		if (request == null || request.IsDisposed ||
			!TryCreateContext(request, out ResourceRequestContext context))
		{
			return null;
		}

		ResourceRuleEvaluation evaluation = _pipeline.Evaluate(context);
		if (evaluation.Plan.Outcome == ResourceInterceptionOutcome.RewriteRemote)
		{
			return new RemoteResourceRequestHandler(evaluation.Plan, _remoteExecutor);
		}
		if (evaluation.Plan.Outcome != ResourceInterceptionOutcome.LocalResponse)
		{
			return null;
		}

		disableDefaultHandling = true;
		return new LocalResourceRequestHandler(
			evaluation.Plan.LocalContent,
			evaluation.Plan.ContentType);
	}

	private sealed class RemoteResourceRequestHandler : ResourceRequestHandler
	{
		private readonly ResourceInterceptionPlan _plan;
		private readonly RemoteResourcePlanExecutor _executor;
		private readonly CancellationTokenSource _cancellation = new CancellationTokenSource();
		private readonly object _sync = new object();
		private ResourceTransformResult _result;
		private bool _disposed;

		public RemoteResourceRequestHandler(
			ResourceInterceptionPlan plan,
			RemoteResourcePlanExecutor executor)
		{
			_plan = plan ?? throw new ArgumentNullException(nameof(plan));
			_executor = executor ?? throw new ArgumentNullException(nameof(executor));
		}

		protected override CefReturnValue OnBeforeResourceLoad(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request,
			IRequestCallback callback)
		{
			ResolveAndContinueAsync(callback);
			return CefReturnValue.ContinueAsync;
		}

		protected override IResourceHandler GetResourceHandler(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request)
		{
			ResourceTransformResult result;
			lock (_sync)
			{
				result = _result;
			}
			return result != null && result.Succeeded
				? ResourceHandler.FromByteArray(result.Content, result.ContentType)
				: null;
		}

		protected override void Dispose()
		{
			lock (_sync)
			{
				if (_disposed)
				{
					return;
				}
				_disposed = true;
				_cancellation.Cancel();
			}
			_cancellation.Dispose();
		}

		private async void ResolveAndContinueAsync(IRequestCallback callback)
		{
			bool cancelled = false;
			try
			{
				ResourceTransformResult result = await _executor.ExecuteAsync(
					_plan,
					_cancellation.Token).ConfigureAwait(false);
				lock (_sync)
				{
					if (!_disposed)
					{
						_result = result;
					}
					else
					{
						cancelled = true;
					}
				}
			}
			catch (OperationCanceledException)
			{
				cancelled = true;
			}
			catch
			{
				// Leave the result empty so Cef continues the untouched original request.
			}
			finally
			{
				try
				{
					if (!callback.IsDisposed)
					{
						if (cancelled)
						{
							callback.Cancel();
						}
						else
						{
							callback.Continue(true);
						}
					}
				}
				finally
				{
					callback.Dispose();
				}
			}
		}
	}

	private static bool TryCreateContext(IRequest request, out ResourceRequestContext context)
	{
		context = null;
		try
		{
			Dictionary<string, string> headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
			NameValueCollection requestHeaders = request.Headers;
			if (requestHeaders != null)
			{
				foreach (string name in requestHeaders.AllKeys)
				{
					if (!string.IsNullOrWhiteSpace(name))
					{
						headers[name] = requestHeaders[name] ?? string.Empty;
					}
				}
			}
			context = new ResourceRequestContext(
				request.Url,
				request.Method,
				request.ResourceType.ToString(),
				headers);
			return true;
		}
		catch (ArgumentException)
		{
			return false;
		}
		catch (ObjectDisposedException)
		{
			return false;
		}
	}

	private sealed class LocalResourceRequestHandler : ResourceRequestHandler
	{
		private readonly byte[] _content;
		private readonly string _contentType;

		public LocalResourceRequestHandler(byte[] content, string contentType)
		{
			_content = content ?? throw new ArgumentNullException(nameof(content));
			_contentType = contentType ?? throw new ArgumentNullException(nameof(contentType));
		}

		protected override IResourceHandler GetResourceHandler(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request)
		{
			return ResourceHandler.FromByteArray(_content, _contentType);
		}
	}
}
