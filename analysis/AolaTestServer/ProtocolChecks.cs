using System.Net;
using System.Net.Sockets;
using System.Text;
using AolaSocketHack.Protocol;
using Newtonsoft.Json.Linq;

namespace AolaTestServer;

internal static class ProtocolChecks
{
	public static async Task Run()
	{
		using var stop = new CancellationTokenSource(TimeSpan.FromSeconds(10));
		var listener = new TcpListener(IPAddress.Loopback, 0);
		listener.Start();
		using var client = new TcpClient();
		await client.ConnectAsync(IPAddress.Loopback, ((IPEndPoint)listener.LocalEndpoint).Port, stop.Token);
		Task serving = new GameServer().Handle(await listener.AcceptTcpClientAsync(stop.Token), stop.Token);
		listener.Stop();
		NetworkStream stream = client.GetStream();
		using (var result = new MemoryStream())
		{
			byte[] one = new byte[1];
			while (await stream.ReadAsync(one, stop.Token) != 0 && one[0] != 0) result.WriteByte(one[0]);
			Require(Encoding.UTF8.GetString(result.ToArray()) == WebServer.Policy, "Flash 策略响应");
		}
		byte[] login = ClientSystem(10016, writer =>
		{
			ServerFrames.Utf(writer, TestPlayer.Zone);
			ServerFrames.Utf(writer, TestPlayer.Id.ToString());
			ServerFrames.Utf(writer, TestPlayer.Session);
		});
		await stream.WriteAsync(login.AsMemory(0, 3), stop.Token);
		await stream.WriteAsync(login.AsMemory(3), stop.Token);
		JObject loggedIn = await Receive(stream, stop.Token);
		Require((string)loggedIn["_cmd"] == "logOK" && (int)loggedIn["id"] == TestPlayer.Id, "固定角色登录");
		var sender = new AolaProtocolState();
		sender.SetLogin(TestPlayer.Id, TestPlayer.Session);
		sender.ObserveOuterSequence(0);
		byte[] first = AolaProtocol.BuildClientExtensionFrame(sender, 11, "11_1", "{}");
		Require(AolaProtocol.ParseClientFrame(0, 0, first, sender).DecodeSucceeded, "提交首包序号");
		byte[] second = AolaProtocol.BuildClientExtensionFrame(sender, 11, "getCurrentTime", "{}");
		await stream.WriteAsync(first.Concat(second).ToArray(), stop.Token);
		JObject privileges = await Receive(stream, stop.Token);
		JObject time = await Receive(stream, stop.Token);
		Require((string)privileges["_cmd"] == "11_1r" && privileges["services"] is JArray, "会员响应命令与连续序号");
		Require((string)time["_cmd"] == "getCurrentTime" && (long)time["t"] > 0, "粘包与服务器时间");
		await stream.WriteAsync(ClientSystem(10012, writer =>
		{
			ServerFrames.Utf(writer, TestPlayer.Scene);
			writer.Write((byte)1);
			ServerFrames.Int32(writer, -1);
			writer.Write((byte)0);
			ServerFrames.Utf(writer, "");
		}), stop.Token);
		JObject room = await Receive(stream, stop.Token);
		Require((string)room["roomName"] == TestPlayer.Scene && (int)room["users"][0]["userId"] == TestPlayer.Id, "房间与角色响应");
		client.Close();
		await serving;
		Console.WriteLine("PASS：本机 TCP 策略、分片登录、加密请求、连续序号、粘包与房间响应。Flash 画面尚未验收。");
	}

	private static byte[] ClientSystem(int action, Action<BinaryWriter> payload)
	{
		byte[] packet = ServerFrames.System(action, -1, payload);
		using var stream = new MemoryStream();
		using var writer = new BinaryWriter(stream);
		ServerFrames.Int32(writer, packet.Length);
		ServerFrames.Int32(writer, 0);
		writer.Write(packet, 4, packet.Length - 4);
		return stream.ToArray();
	}

	private static async Task<JObject> Receive(NetworkStream stream, CancellationToken stop)
	{
		byte[] size = new byte[4];
		await stream.ReadExactlyAsync(size, stop);
		int length = (int)AolaProtocol.ReadUInt32(size, 0);
		byte[] frame = new byte[length + 4];
		size.CopyTo(frame, 0);
		await stream.ReadExactlyAsync(frame.AsMemory(4), stop);
		var packet = AolaProtocol.ParseServerFrame(0, 0, frame);
		Require(packet.DecodeSucceeded, "服务端响应可解析");
		return JObject.Parse(packet.ParametersJson);
	}

	private static void Require(bool passed, string check)
	{
		if (!passed) throw new InvalidOperationException("FAIL：" + check);
	}
}
