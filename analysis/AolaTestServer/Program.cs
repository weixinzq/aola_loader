namespace AolaTestServer;

internal static class Program
{
	public static async Task Main(string[] args)
	{
		Console.OutputEncoding = new System.Text.UTF8Encoding(false);
		if (args.Contains("--self-test"))
		{
			await ProtocolChecks.Run();
			return;
		}
		string root = args.Length == 0 ? Path.Combine(AppContext.BaseDirectory, "cache") : Path.GetFullPath(args[0]);
		using var stop = new CancellationTokenSource();
		Console.CancelKeyPress += (_, e) => { e.Cancel = true; stop.Cancel(); };
		Console.WriteLine("奥拉本地测试服：http://127.0.0.1:18080/play/play.html，游戏端口 18081。Ctrl+C 停止。");
		try
		{
			await Task.WhenAll(new GameServer().Run(stop.Token), new WebServer(root).Run(stop.Token));
		}
		catch (OperationCanceledException) when (stop.IsCancellationRequested) { }
	}
}
