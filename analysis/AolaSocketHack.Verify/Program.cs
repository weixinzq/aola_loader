using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using AolaSocketHack.Contracts;
using AolaSocketHack.Protocol;
using AolaSocketHack.Transport;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class Program
{
	private static int Main(string[] args)
	{
		if (args.Length < 2)
		{
			Console.Error.WriteLine("Usage: AolaSocketHack.Verify <tshark.exe> <capture.pcapng> [tcp.stream]");
			return 2;
		}

		string tshark = Path.GetFullPath(args[0]);
		string capture = Path.GetFullPath(args[1]);
		string stream = args.Length > 2 ? args[2] : "2";
		if (!File.Exists(tshark) || !File.Exists(capture))
		{
			Console.Error.WriteLine("tshark or capture file does not exist");
			return 2;
		}

		Dictionary<long, byte> clientBytes = new Dictionary<long, byte>();
		Dictionary<long, byte> serverBytes = new Dictionary<long, byte>();
		ProcessStartInfo startInfo = new ProcessStartInfo
		{
			FileName = tshark,
			Arguments = string.Format(CultureInfo.InvariantCulture, "-r \"{0}\" -Y \"tcp.stream == {1} && tcp.len > 0\" -T fields -E separator=, -e tcp.srcport -e tcp.seq -e tcp.payload", capture, stream),
			UseShellExecute = false,
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			CreateNoWindow = true
		};
		using (Process process = Process.Start(startInfo))
		{
			string line;
			while ((line = process.StandardOutput.ReadLine()) != null)
			{
				string[] fields = line.Split(new[] { ',' }, 3);
				if (fields.Length != 3 || !int.TryParse(fields[0], out int sourcePort) || !long.TryParse(fields[1], out long sequence))
				{
					continue;
				}
				byte[] payload = HexToBytes(fields[2]);
				Dictionary<long, byte> target = sourcePort >= 8000 && sourcePort <= 8100 ? serverBytes : clientBytes;
				for (int i = 0; i < payload.Length; i++)
				{
					if (!target.ContainsKey(sequence + i))
					{
						target[sequence + i] = payload[i];
					}
				}
			}
			process.WaitForExit();
			if (process.ExitCode != 0)
			{
				Console.Error.WriteLine(process.StandardError.ReadToEnd());
				return process.ExitCode;
			}
		}

		byte[] client = Reassemble(clientBytes);
		byte[] server = Reassemble(serverBytes);
		List<AolaPacketEvent> events = new List<AolaPacketEvent>();
		AolaCaptureEngine engine = new AolaCaptureEngine(events.Add);
		const long socket = 1;
		engine.NoteConnect(socket, 8007);
		engine.CaptureSend(socket, client);
		engine.CaptureReceive(socket, server);

		int sent = events.Count(value => value.Direction == "发送");
		int received = events.Count(value => value.Direction == "接收" && value.MessageType.HasValue);
		int policies = events.Count(value => value.Summary == "Flash cross-domain policy");
		int exportable = events.Count(value => value.CanExport);
		int failures = events.Count(value => !value.DecodeSucceeded);
		List<string> sendLines = events.Where(value => value.CanExport)
			.Select(value => AolaSendExporter.TryCreateLine(value, out string line) ? line : null)
			.ToList();
		bool exportsValid = sendLines.Count == 164 && sendLines.All(line =>
			line != null && line.StartsWith("#send={", StringComparison.Ordinal) &&
			line.EndsWith("}|", StringComparison.Ordinal) &&
			line.IndexOf(":ext_seq;", StringComparison.Ordinal) < 0);
		AolaPacketEvent login = events.FirstOrDefault(value => value.Command == "logIn");
		bool loginRedacted = login != null && login.RawHex == "<登录帧已脱敏>";
		bool innerPlaintextValid = events.Where(value => value.CanExport)
			.All(value => !string.IsNullOrWhiteSpace(value.InnerPlainHex) && string.IsNullOrEmpty(value.RawHex));
		bool activeSendValid = VerifyActiveSend(client);
		Console.WriteLine("client_bytes={0} server_bytes={1}", client.Length, server.Length);
		Console.WriteLine("sent={0} received={1} policy={2} exportable={3} failures={4} export_format={5} login_redacted={6} inner_plaintext={7} active_send={8}", sent, received, policies, exportable, failures, exportsValid, loginRedacted, innerPlaintextValid, activeSendValid);

		bool passed = client.Length == 12373 && server.Length == 286678 && sent == 172 && received == 423 && policies == 1 && exportable == 164 && failures == 0 && exportsValid && loginRedacted && innerPlaintextValid && activeSendValid;
		Console.WriteLine(passed ? "Aola PCAP replay: PASS" : "Aola PCAP replay: FAIL");
		return passed ? 0 : 1;
	}

	private static bool VerifyActiveSend(byte[] client)
	{
		if (client == null || client.Length < 8)
		{
			return false;
		}
		int payloadLength = unchecked((int)AolaProtocol.ReadUInt32(client, 0));
		if (payloadLength <= 0 || payloadLength + 4 > client.Length)
		{
			return false;
		}
		byte[] loginFrame = new byte[payloadLength + 4];
		Buffer.BlockCopy(client, 0, loginFrame, 0, loginFrame.Length);
		AolaProtocolState state = new AolaProtocolState();
		AolaPacketEvent login = AolaProtocol.ParseClientFrame(1, 0, loginFrame, state);
		if (!login.DecodeSucceeded || login.Command != "logIn")
		{
			return false;
		}
		const string parameters = "{\"index\":0,\"flag\":true,\"name\":\"测试\",\"values\":[1,2.5,null]}";
		byte[] frame = AolaProtocol.BuildClientExtensionFrame(state, 42, "VERIFY_SEND", parameters);
		AolaPacketEvent packet = AolaProtocol.ParseClientFrame(1, 0, frame, state);
		if (!packet.DecodeSucceeded || !packet.CanExport || packet.ExtensionId != 42 || packet.Command != "VERIFY_SEND")
		{
			return false;
		}
		JObject decoded = JObject.Parse(packet.ParametersJson);
		if (decoded[":ext_seq;"] != null || decoded.Value<int>("index") != 0 || decoded.Value<bool>("flag") != true || decoded.Value<string>("name") != "测试")
		{
			return false;
		}
		return AolaSendExporter.TryCreateLine(packet, out string line) &&
			line.StartsWith("#send={\"id\":42,\"param\":", StringComparison.Ordinal) &&
			line.EndsWith(",\"cmd\":\"VERIFY_SEND\"}|", StringComparison.Ordinal);
	}

	private static byte[] Reassemble(Dictionary<long, byte> bytes)
	{
		if (bytes.Count == 0)
		{
			return Array.Empty<byte>();
		}
		long first = bytes.Keys.Min();
		long last = bytes.Keys.Max();
		byte[] result = new byte[checked((int)(last - first + 1))];
		for (long position = first; position <= last; position++)
		{
			if (!bytes.TryGetValue(position, out byte value))
			{
				throw new InvalidOperationException("TCP stream contains a gap at sequence " + position);
			}
			result[position - first] = value;
		}
		return result;
	}

	private static byte[] HexToBytes(string value)
	{
		value = value.Replace(":", string.Empty).Trim();
		byte[] result = new byte[value.Length / 2];
		for (int i = 0; i < result.Length; i++)
		{
			result[i] = byte.Parse(value.Substring(i * 2, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
		}
		return result;
	}
}
