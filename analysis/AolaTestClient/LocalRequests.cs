using System;
using System.IO;
using CefSharp;
using CefSharp.Handler;

namespace AolaTestClient;

internal sealed class LocalRequests : RequestHandler
{
	protected override IResourceRequestHandler GetResourceRequestHandler(IWebBrowser chromiumWebBrowser,
		IBrowser browser, IFrame frame, IRequest request, bool isNavigation, bool isDownload,
		string requestInitiator, ref bool disableDefaultHandling) => new LocalResource();

	private sealed class LocalResource : ResourceRequestHandler
	{
		protected override CefReturnValue OnBeforeResourceLoad(IWebBrowser chromiumWebBrowser,
			IBrowser browser, IFrame frame, IRequest request, IRequestCallback callback)
		{
			var url = new Uri(request.Url);
			if (url.Host == "127.0.0.1") return CefReturnValue.Continue;
			File.AppendAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "client-console.log"),
				"已阻止测试客户端的外部请求：" + url.GetLeftPart(UriPartial.Path) + Environment.NewLine);
			return CefReturnValue.Cancel;
		}
	}
}
