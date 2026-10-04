// 架构角色：只替换已核对版本的控制栏模块，为主题热切换提供 Flash 端接口。
// 数据流：controlv2 请求 -> 本地候选字节；其他请求放行。
using System.IO;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Theme.ResourceInterception;

internal sealed class ThemeControlBridgeResourceRule : IResourceInterceptionRule
{
	private readonly byte[] _content;
	private readonly bool _enabled;
	public ThemeControlBridgeResourceRule(string path, bool enabled)
	{
		_enabled = enabled;
		_content = enabled ? File.ReadAllBytes(path) : null;
	}
	public string Name => "theme.controlbar.bridge";
	public int Priority => 801;
	public string PathOwnership => "aola.100bt.com:/play/control/controlv2~2026082731219998.swf";
	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request) =>
		_enabled && request.Method == "GET" && request.Host == "aola.100bt.com" &&
		request.Path == "/play/control/controlv2~2026082731219998.swf"
			? ResourceInterceptionPlan.LocalResponse(request.OriginalUrl, _content,
				"application/x-shockwave-flash", "theme:controlv2:2026082731219998", Name)
			: ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
}
