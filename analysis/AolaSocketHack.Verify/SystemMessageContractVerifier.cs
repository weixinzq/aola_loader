using System;
using System.Collections.Generic;
using System.Text;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;
using AolaSocketHack.Transport;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class SystemMessageContractVerifier
{
	public static bool VerifyConnectionIdentity()
	{
		var packets = new List<AolaPacketEvent>();
		using var engine = new AolaCaptureEngine(packets.Add);
		engine.NoteConnect(1, 8007);
		var body = new List<byte> { 0 };
		WriteUInt16(body, 10016);
		WriteInt32(body, -1);
		WriteUtf(body, "fixture-zone");
		WriteUtf(body, "244677147");
		WriteUtf(body, "offline-fixture");
		var frame = new List<byte>();
		WriteInt32(frame, body.Count + 4);
		WriteInt32(frame, 0);
		frame.AddRange(body);
		engine.CaptureSend(1, frame.ToArray());
		byte[] server = CreateSystemFrame(29999, -1, payload => { });
		engine.CaptureReceive(1, server);
		if (packets.Count != 2 || packets[0].RawHex != "<登录帧已脱敏>" || packets[1].ConnectionPlayerId != 244677147) return false;
		engine.Remove(1);
		engine.NoteConnect(1, 8007);
		engine.CaptureReceive(1, server);
		return packets[2].ConnectionPlayerId == null;
	}
	public static bool Verify()
	{
		try
		{
			return VerifyJoinOk() && VerifyPublicMessage() && VerifyUnknownSystemMessage();
		}
		catch (Exception ex)
		{
			Console.Error.WriteLine("SystemMessage verifier exception: " + ex.GetType().FullName + ": " + ex.Message);
			return false;
		}
	}

	private static bool VerifyJoinOk()
	{
		byte[] frame = CreateSystemFrame(20019, 10902, payload =>
		{
			WriteInt32(payload, 10902);
			WriteUtf(payload, "chunqingmuchang");
			WriteInt32(payload, 100);
			WriteUtf(payload, string.Empty);
			WriteUInt16(payload, 1);
			WriteVariable(payload, "weather", 's', "sun");
			WriteUInt16(payload, 1);
			WriteInt32(payload, 94617668);
			WriteUtf(payload, "tester");
			WriteUInt16(payload, 1);
			WriteVariable(payload, "nns", 's', "hero");
		});

		AolaPacketEvent packet = AolaProtocol.ParseServerFrame(7, 42, frame);
		JObject parameters = JObject.Parse(packet.ParametersJson);
		return packet.DecodeSucceeded && packet.MessageType == 0 && packet.Action == 20019 &&
			packet.Command == "joinOK" &&
			(int?)parameters["headerRoomId"] == 10902 &&
			(int?)parameters["roomId"] == 10902 &&
			(string)parameters["roomName"] == "chunqingmuchang" &&
			(int?)parameters["maxUsers"] == 100 &&
			parameters["roomVariables"] is JArray roomVariables && roomVariables.Count == 1 &&
			(string)roomVariables[0]?["name"] == "weather" &&
			parameters["users"] is JArray users && users.Count == 1 &&
			(int?)users[0]?["userId"] == 94617668 &&
			(string)users[0]?["variables"]?[0]?["value"] == "hero" &&
			packet.Summary.Contains("chunqingmuchang") &&
			!string.IsNullOrWhiteSpace(packet.RawHex);
	}

	private static bool VerifyPublicMessage()
	{
		byte[] frame = CreateSystemFrame(20026, 10902, payload =>
		{
			WriteInt32(payload, 94617668);
			WriteUtf(payload, "[Action]ldzn");
		});
		AolaPacketEvent packet = AolaProtocol.ParseServerFrame(7, 42, frame);
		JObject parameters = JObject.Parse(packet.ParametersJson);
		return packet.DecodeSucceeded && packet.Command == "pubMsg" &&
			(int?)parameters["userId"] == 94617668 &&
			(string)parameters["message"] == "[Action]ldzn";
	}

	private static bool VerifyUnknownSystemMessage()
	{
		byte[] frame = CreateSystemFrame(29999, -1, payload => payload.AddRange(new byte[] { 0xDE, 0xAD, 0xBE, 0xEF }));
		AolaPacketEvent packet = AolaProtocol.ParseServerFrame(7, 42, frame);
		JObject parameters = JObject.Parse(packet.ParametersJson);
		return packet.DecodeSucceeded && packet.Action == 29999 && packet.Command == "system_29999" &&
			(int?)parameters["headerRoomId"] == -1 &&
			(string)parameters["payloadHex"] == "de ad be ef";
	}

	private static byte[] CreateSystemFrame(int action, int roomId, Action<List<byte>> appendPayload)
	{
		List<byte> body = new List<byte> { 0 };
		WriteUInt16(body, action);
		WriteInt32(body, roomId);
		appendPayload(body);
		List<byte> frame = new List<byte>();
		WriteInt32(frame, body.Count);
		frame.AddRange(body);
		return frame.ToArray();
	}

	private static void WriteVariable(List<byte> destination, string name, char type, string value)
	{
		WriteUtf(destination, name);
		destination.Add((byte)type);
		WriteUtf(destination, value);
	}

	private static void WriteUtf(List<byte> destination, string value)
	{
		byte[] bytes = Encoding.UTF8.GetBytes(value);
		WriteUInt16(destination, bytes.Length);
		destination.AddRange(bytes);
	}

	private static void WriteUInt16(List<byte> destination, int value)
	{
		destination.Add((byte)(value >> 8));
		destination.Add((byte)value);
	}

	private static void WriteInt32(List<byte> destination, int value)
	{
		uint unsigned = unchecked((uint)value);
		destination.Add((byte)(unsigned >> 24));
		destination.Add((byte)(unsigned >> 16));
		destination.Add((byte)(unsigned >> 8));
		destination.Add((byte)unsigned);
	}
}
