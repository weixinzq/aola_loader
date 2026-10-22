using System.Net;
using System.Net.Sockets;
using System.Text;
using AolaSocketHack.Protocol;
using AolaSocketHack.Transport;
using Newtonsoft.Json.Linq;

namespace AolaTestServer;

internal sealed class GameServer
{
	public async Task Run(CancellationToken stop)
	{
		var listener = new TcpListener(IPAddress.Loopback, 18081);
		listener.Start();
		var clients = new List<Task>();
		try
		{
			while (!stop.IsCancellationRequested)
			{
				TcpClient client = await listener.AcceptTcpClientAsync(stop);
				clients.RemoveAll(task => task.IsCompleted);
				clients.Add(Handle(client, stop));
			}
		}
		finally
		{
			listener.Stop();
			await Task.WhenAll(clients);
		}
	}

	internal async Task Handle(TcpClient client, CancellationToken stop)
	{
		using (client)
		{
			var state = new AolaProtocolState();
			var frames = new FrameBuffer();
			int room = -1;
			JObject variables = TestPlayer.Variables();
			NetworkStream stream = client.GetStream();
			try
			{
				await stream.WriteAsync(Encoding.UTF8.GetBytes(WebServer.Policy + "\0"), stop);
				byte[] buffer = new byte[16384];
				int count;
				while ((count = await stream.ReadAsync(buffer, stop)) > 0)
				{
					if (!frames.TryAppend(buffer.Take(count).ToArray())) break;
					byte[] policyPrefix = Encoding.ASCII.GetBytes("<policy-file-request/>");
					if (frames.CouldStartWith(policyPrefix))
					{
						if (!frames.TryTakeNullTerminated(1024, out _, out _)) continue;
						return;
					}
					while (frames.TryTakeFrame(out byte[] frame, out bool invalid))
					{
						var packet = AolaProtocol.ParseClientFrame(0, 0, frame, state);
						if (!packet.DecodeSucceeded) throw new InvalidDataException(packet.Summary);
						byte[] response = null;
						if (packet.Action == 10016)
						{
							if (state.UserId != TestPlayer.Id) throw new InvalidDataException("请使用独立入口的固定测试角色。");
							response = ServerFrames.Extension(new JObject
							{
								["_cmd"] = "logOK", ["id"] = TestPlayer.Id, ["n"] = TestPlayer.Id.ToString(),
								["lastLoginTime"] = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
							});
							Console.WriteLine("[登录] 固定测试角色已接入。");
						}
						else if (packet.Action == 10033)
						{
							JObject data = TestPlayer.Response(packet.Command);
							Console.WriteLine($"[{(data == null ? "未实现" : "响应")}] EXT {packet.ExtensionId} {packet.Command}");
							if (data != null) response = ServerFrames.Extension(data);
						}
						else if (packet.Action == 10012)
						{
							byte[] body = DecodeSystemBody(frame);
							int cursor = 7;
							string name = ReadUtf(body, ref cursor);
							room = 10902;
							response = ServerFrames.System(20019, room, writer =>
							{
								ServerFrames.Int32(writer, room);
								ServerFrames.Utf(writer, name);
								ServerFrames.Int32(writer, 1);
								ServerFrames.Utf(writer, "");
								ServerFrames.Variables(writer, new JObject());
								ServerFrames.Int16(writer, 1);
								ServerFrames.Int32(writer, TestPlayer.Id);
								ServerFrames.Utf(writer, TestPlayer.Id.ToString());
								ServerFrames.Variables(writer, variables);
							});
							Console.WriteLine($"[房间] {name}：已发送角色与房间数据；画面显示待客户端确认。");
						}
						else if (packet.Action == 10028)
						{
							byte[] body = DecodeSystemBody(frame);
							int cursor = 7;
							int variableCount = AolaProtocol.ReadUInt16(body, cursor);
							cursor += 2;
							for (int i = 0; i < variableCount; i++)
							{
								string key = ReadUtf(body, ref cursor);
								char type = (char)body[cursor++];
								string value = ReadUtf(body, ref cursor);
								variables[key] = type == 'n' ? JToken.FromObject(double.Parse(value, System.Globalization.CultureInfo.InvariantCulture)) : type == 'b' ? JToken.FromObject(value == "1") : JToken.FromObject(value);
							}
							response = ServerFrames.System(20039, room, writer =>
							{
								ServerFrames.Int32(writer, TestPlayer.Id);
								ServerFrames.Variables(writer, variables);
							});
						}
						else if (packet.Action != 10011) Console.WriteLine($"[未实现] SYS {packet.Action}");
						if (response != null) await stream.WriteAsync(response, stop);
					}
				}
			}
			catch (OperationCanceledException) when (stop.IsCancellationRequested) { }
			catch (Exception ex) when (ex is IOException || ex is SocketException || ex is InvalidDataException)
			{
				Console.WriteLine("[连接关闭] " + ex.Message);
			}
			finally { frames.Clear(); }
		}
	}

	internal static byte[] DecodeSystemBody(byte[] frame)
	{
		byte[] body = frame.Skip(8).ToArray();
		for (int i = 0; i < body.Length; i++) body[i] ^= frame[4 + i % 4];
		return body;
	}

	internal static string ReadUtf(byte[] body, ref int cursor)
	{
		int length = AolaProtocol.ReadUInt16(body, cursor);
		cursor += 2;
		string value = Encoding.UTF8.GetString(body, cursor, length);
		cursor += length;
		return value;
	}
}
