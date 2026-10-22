using System;
using System.IO;
using System.Windows.Forms;
using AolaLoader.BrowserHost;
using CefSharp;
using CefSharp.WinForms;

namespace AolaTestClient;

internal static class Program
{
	[STAThread]
	private static void Main(string[] args)
	{
		Application.EnableVisualStyles();
		Application.SetCompatibleTextRenderingDefault(false);
		AolaCefInitializer.Initialize();
		try
		{
			using (var form = new Form { Text = "奥拉本地测试服", ClientSize = new System.Drawing.Size(1000, 620) })
			using (var browser = new ChromiumWebBrowser("http://127.0.0.1:18080/play/play.html") { Dock = DockStyle.Fill, RequestHandler = new LocalRequests() })
			{
				browser.ConsoleMessage += (_, e) => File.AppendAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "client-console.log"), e.Message + Environment.NewLine);
				form.Controls.Add(browser);
				if (Array.IndexOf(args, "--capture") >= 0)
				{
					var timer = new Timer { Interval = 30000 };
					timer.Tick += async (_, e) =>
					{
						timer.Stop();
						using (var tools = browser.GetDevToolsClient())
						{
							var screenshot = await tools.Page.CaptureScreenshotAsync();
							File.WriteAllBytes(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "client.png"), screenshot.Data);
						}
						form.Close();
						timer.Dispose();
					};
					timer.Start();
				}
				Application.Run(form);
			}
		}
		finally { Cef.Shutdown(); }
	}
}
