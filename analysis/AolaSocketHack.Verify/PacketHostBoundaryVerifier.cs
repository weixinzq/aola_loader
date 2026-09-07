using System;
using System.IO;
using System.Text;
using AolaLoader.PacketHost;
using AolaLoader.PacketHost.Consumers;
using AolaLoader.PacketHost.Testing;
using AolaLoader.UI.Packets;
using AolaSocketHack.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class PacketHostBoundaryVerifier
{
	public static bool Verify()
	{
		if (!PacketHostSourceGuardVerifier.Verify() || !VerifySendPacketVisibility())
		{
			return false;
		}
		AolaHookHostService service = new AolaHookHostService();
		AolaPacketEvent packet = new AolaPacketEvent { Direction = "发送" };
		AolaHookStatus status = new AolaHookStatus { Message = "ready" };
		AolaSendResult sendResult = new AolaSendResult { RequestId = "result-1" };
		int packetDeliveries = 0;
		int statusDeliveries = 0;
		int resultDeliveries = 0;

		AolaHookHostAdapter adapter = new AolaHookHostAdapter();
		adapter.PacketReceived += value => throw new InvalidOperationException("expected subscriber failure");
		adapter.PacketReceived += value => packetDeliveries++;
		adapter.StatusReceived += value => statusDeliveries++;
		adapter.SendCompleted += value => resultDeliveries++;

		service.Publish(packet);
		service.Report(status);
		service.PublishSendResult(sendResult);
		if (packetDeliveries != 1 || statusDeliveries != 1 || resultDeliveries != 1)
		{
			adapter.Dispose();
			return false;
		}

		AolaSendRequest request = new AolaSendRequest
		{
			ProcessId = 9933,
			ExtensionId = 42,
			Command = "PacketHostVerify",
			ParametersJson = "{}"
		};
		string requestId = adapter.QueueSend(request);
		AolaSendRequest queued = service.TakeSendRequest(9933);
		if (queued != request || string.IsNullOrWhiteSpace(requestId) || queued.RequestId != requestId)
		{
			adapter.Dispose();
			return false;
		}

		adapter.Dispose();
		service.Publish(packet);
		service.Report(status);
		service.PublishSendResult(sendResult);
		if (packetDeliveries != 1 || statusDeliveries != 1 || resultDeliveries != 1 ||
			!Throws<ObjectDisposedException>(() => adapter.QueueSend(request)))
		{
			return false;
		}

		int manualDeliveries = 0;
		ManualAolaPacketEventSource manual = new ManualAolaPacketEventSource
		{
			QueueSendHandler = value => "manual-request"
		};
		manual.PacketReceived += value => throw new InvalidOperationException("expected subscriber failure");
		manual.PacketReceived += value => manualDeliveries++;
		manual.PublishPacket(packet);
		if (manualDeliveries != 1 || manual.QueueSend(request) != "manual-request")
		{
			manual.Dispose();
			return false;
		}
		manual.Dispose();
		if (!Throws<ObjectDisposedException>(() => manual.PublishPacket(packet)))
		{
			return false;
		}
		try
		{
			return VerifyReceiveLoggerConsumer();
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine("ReceiveLogger verifier exception: " +
				ex.GetType().FullName + ": " + ex.Message);
			return false;
		}
	}

	private static bool VerifySendPacketVisibility()
	{
		return !SendPacketVisibility.IsVisible(null) &&
			SendPacketVisibility.IsVisible(new AolaPacketEvent { Direction = "发送" }) &&
			!SendPacketVisibility.IsVisible(new AolaPacketEvent { Direction = "接收" }) &&
			!SendPacketVisibility.IsVisible(new AolaPacketEvent { Direction = "发送 " }) &&
			!SendPacketVisibility.IsVisible(new AolaPacketEvent { Direction = "SEND" });
	}

	private static bool VerifyReceiveLoggerConsumer()
	{
		string root = Path.Combine(Path.GetTempPath(), "aola-receive-logger-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(root);
		ManualAolaPacketEventSource source = new ManualAolaPacketEventSource();
		AolaReceiveLogger logger = new AolaReceiveLogger(source, root);
		try
		{
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "接收",
				RawHex = "BEFORE_RETAIN"
			});
			if (!logger.TryRetain(out string path, out string error) || error != null || !File.Exists(path))
			{
				return false;
			}
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "发送",
				ProcessId = 41,
				FrameLength = 12,
				DecodeSucceeded = true,
				MessageType = 1,
				Action = 10033,
				ExtensionId = 15,
				Command = "54_22",
				ParametersJson = "{\"handler\":\"TP230818\"}",
				InnerPlainHex = "0304"
			});
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "接收",
				ProcessId = 42,
				FrameLength = 2,
				DecodeSucceeded = true,
				ParametersJson = "{\"ok\":true}",
				InnerPlainHex = "0102",
				RawHex = "AABB"
			});
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "发送",
				DecodeSucceeded = true,
				MessageType = 0,
				Action = 10016,
				Command = "logIn",
				ParametersJson = "{\"session\":\"SECRET_SESSION\"}",
				InnerPlainHex = "SECRET_INNER",
				RawHex = "SECRET_FRAME"
			});
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "SEND",
				RawHex = "IGNORED_DIRECTION"
			});
			byte[] bytes;
			using (FileStream stream = new FileStream(
				path,
				FileMode.Open,
				FileAccess.Read,
				FileShare.ReadWrite))
			using (MemoryStream copy = new MemoryStream())
			{
				stream.CopyTo(copy);
				bytes = copy.ToArray();
			}
			string text = new UTF8Encoding(false, true).GetString(bytes);
			string[] lines = text.Split(new[] { Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
			if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF ||
				lines.Length != 3 ||
				text.Contains("BEFORE_RETAIN") ||
				text.Contains("SECRET_") ||
				text.Contains("IGNORED_DIRECTION"))
			{
				return false;
			}

			JObject send = null;
			JObject receive = null;
			JObject login = null;
			foreach (string line in lines)
			{
				JObject record = JObject.Parse(line);
				string command = (string)record["cmd"];
				if (command == "54_22")
				{
					send = record;
				}
				else if (command == "logIn")
				{
					login = record;
				}
				else if ((string)record["direction"] == "接收")
				{
					receive = record;
				}
			}
			if (send == null || (string)send["direction"] != "发送" ||
				(int?)send["extensionId"] != 15 ||
				(string)send["param"]?["handler"] != "TP230818" ||
				(string)send["innerPlainHex"] != "0304" ||
				receive == null || (bool?)receive["param"]?["ok"] != true ||
				(string)receive["innerPlainHex"] != "0102" ||
				(string)receive["rawHex"] != "AABB" ||
				login == null || (string)login["rawHex"] != "<登录帧已脱敏>" ||
				login["param"] != null || login["innerPlainHex"] != null)
			{
				return false;
			}

			logger.Dispose();
			long retainedLength = new FileInfo(path).Length;
			source.PublishPacket(new AolaPacketEvent
			{
				TimestampUtc = DateTime.UtcNow,
				Direction = "接收",
				RawHex = "CCDD"
			});
			return !logger.IsActive && new FileInfo(path).Length == retainedLength;
		}
		finally
		{
			logger.Dispose();
			source.Dispose();
			Directory.Delete(root, true);
		}
	}

	private static bool Throws<TException>(Action action) where TException : Exception
	{
		try
		{
			action();
			return false;
		}
		catch (TException)
		{
			return true;
		}
	}
}
