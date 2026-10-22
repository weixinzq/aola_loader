using System.Text;
using System.Xml.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Hosting;

namespace AolaTestServer;

internal sealed class WebServer
{
	public const string Policy = "<cross-domain-policy><allow-access-from domain=\"127.0.0.1\" to-ports=\"18081\"/></cross-domain-policy>";
	private const string BaseUrl = "http://127.0.0.1:18080/";
	private readonly string _cache;
	private readonly HttpClient _assets = new HttpClient();

	public WebServer(string cache) { _cache = cache; }

	public async Task Run(CancellationToken stop)
	{
		var builder = WebApplication.CreateSlimBuilder();
		builder.Logging.ClearProviders();
		builder.WebHost.UseUrls(BaseUrl);
		await using var app = builder.Build();
		app.Run(Handle);
		await app.RunAsync(stop);
	}

	private async Task Handle(HttpContext context)
	{
		string path = context.Request.Path.Value;
		Console.WriteLine("[HTTP] " + path);
		try
		{
			if (path == "/" || path == "/play/play.html")
			{
				context.Response.ContentType = "text/html; charset=utf-8";
				await context.Response.WriteAsync(Page);
				return;
			}
			if (path == "/crossdomain.xml")
			{
				await Xml(context, Policy);
				return;
			}
			if (path == "/newRegister.jsp")
			{
				var form = await context.Request.ReadFormAsync();
				string type = form["type"];
				if (type == "query_role_info") await context.Response.WriteAsync($"0,{TestPlayer.Id},{TestPlayer.Name},0,{TestPlayer.Avatar}|");
				else if (type == "machine_log" || type == "pv_log") await Xml(context, "<r><i>local-test</i><s>local-test</s><t>0</t></r>");
				else { context.Response.StatusCode = 404; Console.WriteLine("[注册接口未实现] " + type); }
				return;
			}
			if (path == "/newLogin.jsp")
			{
				await Xml(context, new XElement("r", new XElement("c", "ok"), new XElement("u", TestPlayer.Id),
					new XElement("d", TestPlayer.Id), new XElement("sid", TestPlayer.Session), new XElement("state", 0),
					new XElement("m", 0), new XElement("num", 0), new XElement("bindaobi", 0),
					new XElement("svr", "127.0.0.1:18081"), new XElement("zn", "1 " + TestPlayer.Zone + "/0/0/0/0/0"),
					new XElement("alday", 1)).ToString());
				Console.WriteLine("[HTTP 登录] 已返回本地测试会话。");
				return;
			}
			if (path == "/CheckAlive.jsp" || path == "/isp.txt")
			{
				await context.Response.WriteAsync("0");
				return;
			}
			if (path == "/client-error")
			{
				Console.WriteLine("[客户端错误] " + context.Request.Query["message"].ToString());
				return;
			}
			if (path == "/clientlogcollect.jsp" || path == "/pushErrorMessage.action")
			{
				var report = await context.Request.ReadFormAsync();
				Console.WriteLine("[客户端报告] " + report["m"].ToString());
				await context.Response.WriteAsync("ok");
				return;
			}
			if (!path.StartsWith("/play/") || context.Request.Method != "GET")
			{
				context.Response.StatusCode = 404;
				Console.WriteLine("[HTTP 未实现] " + path);
				return;
			}
			string asset = path.Substring(6);
			if (asset.StartsWith("start~") && asset.EndsWith(".xml")) asset = "start.xml";
			byte[] bytes = await Asset(asset);
			if (asset.StartsWith("difference~"))
			{
				XDocument difference = XDocument.Load(new MemoryStream(bytes));
				foreach (XElement url in difference.Root.Element("server").Element("urls").Elements())
					if (url.Name.LocalName != "registerUrl") url.Value = BaseUrl;
				bytes = Encoding.UTF8.GetBytes(difference.ToString());
			}
			else if (asset.StartsWith("config~") && asset.EndsWith(".xml"))
			{
				XDocument config = XDocument.Load(new MemoryStream(bytes));
				config.Root.Element("defaultRoom").ReplaceNodes(new XElement("r", new XAttribute("nm", TestPlayer.Scene), new XAttribute("weight", 1)));
				bytes = Encoding.UTF8.GetBytes(config.ToString());
			}
			context.Response.ContentType = asset.EndsWith(".xml") ? "text/xml; charset=utf-8" : asset.EndsWith(".swf") ? "application/x-shockwave-flash" : "application/octet-stream";
			await context.Response.Body.WriteAsync(bytes);
		}
		catch (Exception ex) when (ex is HttpRequestException || ex is IOException)
		{
			Console.WriteLine("[资源失败] " + path + " " + ex.Message);
			context.Response.StatusCode = 502;
		}
	}

	private async Task<byte[]> Asset(string name)
	{
		string path = Path.Combine(_cache, name.Replace('/', Path.DirectorySeparatorChar));
		if (File.Exists(path)) return await File.ReadAllBytesAsync(path);
		byte[] data = await _assets.GetByteArrayAsync("https://aola.100bt.com/play/" + name);
		Directory.CreateDirectory(Path.GetDirectoryName(path));
		await File.WriteAllBytesAsync(path, data);
		Console.WriteLine("[缓存资源] " + name);
		return data;
	}

	private static async Task Xml(HttpContext context, string text)
	{
		context.Response.ContentType = "text/xml; charset=utf-8";
		await context.Response.WriteAsync(text);
	}

	private const string Page = """
<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><title>奥拉本地测试服</title>
<style>html,body{margin:0;background:#161c26;color:#e4e9f0;font:14px 'Microsoft YaHei',sans-serif}header{padding:12px 20px}object{display:block;margin:auto;width:960px;height:560px}</style>
<script>
var localCookie='gameId=2,gameName=aola,duoduoId=10001,token=local-test,autoLogin=false';
function getCookie(key){return String(key)==='game_auth_sid'?localCookie:'';}
function delCookie(key){if(String(key)==='game_auth_sid')localCookie='';}
function addCookieFromAs(){}
function getQS(){return null;}
function getSN(){return 'local-test';}
function getFrom(){return 'local-test';}
function getPlatform(){return 1;}
function showWebLogin(){location.reload();}
function getYiDunToken(){return '';}
function riseLogin(){}
window.onerror=function(message){fetch('/client-error?message='+encodeURIComponent(String(message)));};
function aolaTestError(message){document.querySelector('header').textContent=String(message);fetch('/client-error?message='+encodeURIComponent(String(message)));}
</script></head><body><header>本地测试服 · 固定测试角色 · 游戏连接 127.0.0.1:18081</header>
<object id="Client" name="Client" type="application/x-shockwave-flash" data="start.swf" width="960" height="560">
<param name="movie" value="start.swf"><param name="allowScriptAccess" value="always"><param name="wmode" value="direct"></object>
</body></html>
""";
}
