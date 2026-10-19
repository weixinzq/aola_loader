// 架构角色：获取最新启动 XML，只将开放状态改为 open，保留版本与热更新映射。
using System;
using System.Text;
using System.Text.RegularExpressions;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.ResourceInterception.Rules;

internal sealed class StartXmlResourceRule : IResourceInterceptionRule, IResourceResponseTransformer
{
	private static readonly Regex StartPathPattern = new Regex(
		@"^/play/start(?:~[0-9]+)?\.xml$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly Regex StatusPattern = new Regex(
		@"<t>[^<]*</t>", RegexOptions.Compiled | RegexOptions.CultureInvariant);

	public string Name => "startup.xml.open";

	public int Priority => 1001;

	public string PathOwnership => "aola.100bt.com:/play/start.xml,/play/start~<timestamp>.xml";

	public string InputContract => "UTF-8 start XML";

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) ||
			!StartPathPattern.IsMatch(request.Path))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.RewriteRemote(
			request.OriginalUrl,
			request.OriginalUrl,
			"text/xml",
			this,
			request.OriginalUrl,
			"startup:xml:" + request.OriginalUrl,
			Name,
			1024 * 1024,
			probeRemoteResource: false);
	}

	public ResourceTransformResult Transform(ResourceTransformInput input)
	{
		string xml = Encoding.UTF8.GetString(input.Content);
		return ResourceTransformResult.Success(
			Encoding.UTF8.GetBytes(StatusPattern.Replace(xml, "<t>open</t>", 1)),
			"text/xml");
	}
}
