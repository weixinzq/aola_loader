// 架构角色：面板调用采集的页面端口，仅依赖通用 IPageBridge。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.PanelCapture;

internal sealed class PanelCaptureClient
{
	private readonly IPageBridge _pageBridge;

	public PanelCaptureClient(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge;
	}

	public Task<PageBridgeResult> PollAsync(bool enabled, CancellationToken cancellationToken)
	{
		return _pageBridge.InvokeAsync(new PageBridgeRequest("panelCapture.poll",
			new JObject { ["enabled"] = enabled }, TimeSpan.FromSeconds(3)), cancellationToken);
	}

	public Task<PageBridgeResult> StopAsync()
	{
		return _pageBridge.InvokeAsync(new PageBridgeRequest("panelCapture.stop",
			new JObject(), TimeSpan.FromSeconds(3)), CancellationToken.None);
	}
}
