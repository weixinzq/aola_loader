// 架构角色：独立注册面板调用采集副本，不参与协议捕获和主动打开面板。
using System;
using System.IO;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.PanelCapture.ResourceInterception;

internal sealed class PanelCaptureResourceRule : IResourceInterceptionRule
{
	internal const string Version = "2026101541804528";
	private readonly byte[] _content;

	public PanelCaptureResourceRule(string patchDirectory)
	{
		_content = File.ReadAllBytes(Path.Combine(patchDirectory, "play-panel-capture-" + Version + ".fws.swf"));
	}

	public string Name => "panelcapture.play";
	public int Priority => 849;
	public string PathOwnership => "aola.100bt.com:/play/play~" + Version + ".swf";

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) ||
			!string.Equals(request.Path, "/play/play~" + Version + ".swf", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}
		return ResourceInterceptionPlan.LocalResponse(request.OriginalUrl, _content,
			"application/x-shockwave-flash", "panelcapture:" + Version, Name);
	}
}
