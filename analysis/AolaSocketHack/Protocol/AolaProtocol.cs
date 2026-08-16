using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Protocol;

internal sealed class AolaProtocolState
{
	private const uint InnerMask = 0x1FFFFFFC;
	private const uint InnerNotMask = 0xE0000003;
	private readonly Dictionary<int, int> _innerSequences = new Dictionary<int, int>();
	private int _sessionHash;
	private int _lastOuterSequence;
	private bool _hasOuterSequence;

	public int UserId { get; private set; }

	public bool HasLogin { get; private set; }

	public void SetLogin(int userId, string sessionId)
	{
		UserId = userId;
		HasLogin = userId > 0;
		_sessionHash = HashAs3(sessionId ?? string.Empty);
		_innerSequences.Clear();
	}

	public void ObserveOuterSequence(uint sequence)
	{
		_lastOuterSequence = unchecked((int)sequence);
		_hasOuterSequence = true;
	}

	public int GetNextOuterSequence()
	{
		if (!HasLogin || !_hasOuterSequence)
		{
			throw new InvalidOperationException("尚未捕获完整登录序号");
		}
		if (_lastOuterSequence == 0)
		{
			return 79;
		}
		long next = (long)_lastOuterSequence * 7 + UserId % 991 + _sessionHash % 569;
		if (next >= int.MaxValue)
		{
			next = next % 1047483647 + 911;
		}
		return unchecked((int)next);
	}

	public int GetExpectedInnerBase(int extensionId)
	{
		if (!_innerSequences.TryGetValue(extensionId, out int previous))
		{
			return 18;
		}
		int real = (int)(((uint)previous & InnerMask) >> 2);
		int next = real * 2 + UserId % 108;
		return next < 123216728 ? next : 204;
	}

	public void CommitInnerSequence(int extensionId, int sequence)
	{
		_innerSequences[extensionId] = sequence;
	}

	public int CreateNextInnerSequence(int extensionId)
	{
		int result = GetExpectedInnerBase(extensionId);
		int random0 = NextRandom16();
		int random1 = NextRandom16();
		int random2 = NextRandom16() % 4;
		int temporary = unchecked((random0 << 17) + (random1 << 2) + random2);
		return unchecked((int)(((uint)temporary & InnerNotMask) | ((uint)result << 2)));
	}

	private static int HashAs3(string value)
	{
		int hash = 0;
		foreach (char codeUnit in value)
		{
			hash = unchecked(31 * hash + codeUnit);
		}
		return hash;
	}

	private static int NextRandom16()
	{
		byte[] bytes = new byte[4];
		using (RandomNumberGenerator random = RandomNumberGenerator.Create())
		{
			random.GetBytes(bytes);
		}
		return (int)(BitConverter.ToUInt32(bytes, 0) % 65535u);
	}
}

internal static class AolaProtocol
{
	private const uint InnerMask = 0x1FFFFFFC;
	private static readonly JsonSerializerSettings JsonSettings = new JsonSerializerSettings
	{
		Formatting = Formatting.None,
		ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
		Culture = CultureInfo.InvariantCulture
	};

	public static bool LooksLikeLoginFrame(byte[] frame)
	{
		if (frame == null || frame.Length < 15 || ReadUInt32(frame, 4) != 0)
		{
			return false;
		}
		return frame[8] == 0 && ReadUInt16(frame, 9) == 10016 && ReadUInt32(frame, 11) == uint.MaxValue;
	}

	public static AolaPacketEvent ParseClientFrame(long socket, int processId, byte[] frame, AolaProtocolState state)
	{
		AolaPacketEvent packet = NewPacket(socket, processId, "发送", frame);
		try
		{
			if (frame.Length < 15)
			{
				throw new InvalidOperationException("客户端帧短于最小包头");
			}
			uint sequence = ReadUInt32(frame, 4);
			packet.OuterSequence = sequence;
			byte[] body = Xor(frame, 8, sequence);
			int type = body[0];
			int action = ReadUInt16(body, 1);
			packet.MessageType = type;
			packet.Action = action;
			state.ObserveOuterSequence(sequence);

			if (type == 0 && action == 10016)
			{
				ParseLogin(body, state, packet);
				packet.RawHex = "<登录帧已脱敏>";
				packet.DecodeSucceeded = true;
				return packet;
			}

			if (type == 1 && action == 10033)
			{
				ParseExtension(body, state, packet);
				return packet;
			}

			packet.Summary = string.Format(CultureInfo.InvariantCulture, "type={0}, action={1}", type, action);
			packet.DecodeSucceeded = true;
		}
		catch (Exception ex)
		{
			packet.Summary = "解析失败：" + ex.Message;
		}
		return packet;
	}

	public static byte[] BuildClientExtensionFrame(AolaProtocolState state, int extensionId, string command, string parametersJson)
	{
		if (state == null || !state.HasLogin)
		{
			throw new InvalidOperationException("独立发包连接尚未登录");
		}
		if (extensionId < 0 || extensionId > ushort.MaxValue)
		{
			throw new ArgumentOutOfRangeException(nameof(extensionId));
		}
		if (string.IsNullOrWhiteSpace(command))
		{
			throw new ArgumentException("命令不能为空", nameof(command));
		}

		JObject parameters;
		try
		{
			parameters = string.IsNullOrWhiteSpace(parametersJson) ? new JObject() : JObject.Parse(parametersJson);
		}
		catch (JsonException ex)
		{
			throw new InvalidOperationException("param 必须是 JSON 对象", ex);
		}
		parameters.Remove(":ext_seq;");
		int innerSequence = state.CreateNextInnerSequence(extensionId);
		parameters[":ext_seq;"] = innerSequence;

		Amf3Writer parametersWriter = new Amf3Writer();
		parametersWriter.WriteObject(parameters);
		byte[] encryptedParameters = EncryptInner(innerSequence, parametersWriter.ToArray());
		Amf3Writer wrapperWriter = new Amf3Writer();
		wrapperWriter.WriteObject(new Dictionary<string, object> { ["data"] = encryptedParameters });

		List<byte> body = new List<byte>();
		body.Add(1);
		WriteUInt16(body, 10033);
		WriteUInt32(body, uint.MaxValue);
		WriteUInt16(body, unchecked((ushort)extensionId));
		WriteUtf(body, command);
		body.AddRange(wrapperWriter.ToArray());

		int outerSequence = state.GetNextOuterSequence();
		byte[] plainBody = body.ToArray();
		byte[] encryptedBody = Xor(plainBody, 0, unchecked((uint)outerSequence));
		List<byte> frame = new List<byte>(encryptedBody.Length + 8);
		WriteUInt32(frame, unchecked((uint)(encryptedBody.Length + 4)));
		WriteUInt32(frame, unchecked((uint)outerSequence));
		frame.AddRange(encryptedBody);
		return frame.ToArray();
	}

	public static AolaPacketEvent ParseServerFrame(long socket, int processId, byte[] frame)
	{
		AolaPacketEvent packet = NewPacket(socket, processId, "接收", frame);
		try
		{
			if (frame.Length < 6)
			{
				throw new InvalidOperationException("服务端帧短于最小包头");
			}
			int type = frame[4];
			packet.MessageType = type;
			if (type == 1)
			{
				object value = new Amf3Reader(frame, 5).ReadObject();
				packet.ParametersJson = JsonConvert.SerializeObject(value, JsonSettings);
				if (value is Dictionary<string, object> map && map.TryGetValue("_cmd", out object command))
				{
					packet.Command = Convert.ToString(command, CultureInfo.InvariantCulture);
				}
				packet.Summary = string.IsNullOrEmpty(packet.Command) ? "EXT 服务端推送" : packet.Command;
				packet.DecodeSucceeded = true;
			}
			else
			{
				packet.Summary = "系统消息 type=" + type;
				packet.DecodeSucceeded = true;
			}
		}
		catch (Exception ex)
		{
			packet.Summary = "解析失败：" + ex.Message;
		}
		return packet;
	}

	public static AolaPacketEvent CreatePolicyEvent(long socket, int processId, byte[] policy)
	{
		return new AolaPacketEvent
		{
			TimestampUtc = DateTime.UtcNow,
			ProcessId = processId,
			SocketHandle = socket,
			Direction = "接收",
			FrameLength = policy?.Length ?? 0,
			Summary = "Flash cross-domain policy",
			RawHex = policy == null ? string.Empty : Encoding.ASCII.GetString(policy).TrimEnd('\0'),
			DecodeSucceeded = true
		};
	}

	private static void ParseLogin(byte[] body, AolaProtocolState state, AolaPacketEvent packet)
	{
		int position = 7;
		string zone = ReadUtf(body, ref position);
		string userIdText = ReadUtf(body, ref position);
		string session = ReadUtf(body, ref position);
		if (position != body.Length || !int.TryParse(userIdText, NumberStyles.Integer, CultureInfo.InvariantCulture, out int userId))
		{
			throw new InvalidOperationException("登录字段格式不正确");
		}
		state.SetLogin(userId, session);
		packet.Command = "logIn";
		packet.Summary = string.Format(CultureInfo.InvariantCulture, "登录：zone={0}, userId长度={1}, sid长度={2}", zone, userIdText.Length, Encoding.UTF8.GetByteCount(session));
	}

	private static void ParseExtension(byte[] body, AolaProtocolState state, AolaPacketEvent packet)
	{
		if (body.Length < 11)
		{
			throw new InvalidOperationException("EXT 帧短于最小长度");
		}
		int position = 7;
		int extensionId = ReadUInt16(body, position);
		position += 2;
		string command = ReadUtf(body, ref position);
		object wrapperValue = new Amf3Reader(body, position).ReadObject();
		if (!(wrapperValue is Dictionary<string, object> wrapper) || !wrapper.TryGetValue("data", out object encryptedValue) || !(encryptedValue is byte[] encrypted))
		{
			throw new InvalidOperationException("EXT 缺少 AMF3 data ByteArray");
		}
		if (!state.HasLogin)
		{
			throw new InvalidOperationException("未捕获登录帧，无法推导 InnerSeq");
		}

		int expectedBase = state.GetExpectedInnerBase(extensionId);
		byte[] decrypted = DecryptInner(expectedBase << 2, encrypted);
		packet.InnerPlainHex = ToHex(decrypted);
		packet.RawHex = string.Empty;
		object parameters = new Amf3Reader(decrypted).ReadObject();
		if (!(parameters is Dictionary<string, object> map) || !map.TryGetValue(":ext_seq;", out object sequenceValue))
		{
			throw new InvalidOperationException("解密结果缺少 :ext_seq;");
		}
		int sequence = Convert.ToInt32(sequenceValue, CultureInfo.InvariantCulture);
		int actualBase = (int)(((uint)sequence & InnerMask) >> 2);
		if (actualBase != expectedBase)
		{
			throw new InvalidOperationException(string.Format(CultureInfo.InvariantCulture, "InnerSeq 不连续，expected={0}, actual={1}", expectedBase, actualBase));
		}
		state.CommitInnerSequence(extensionId, sequence);
		map.Remove(":ext_seq;");

		packet.ExtensionId = extensionId;
		packet.Command = command;
		packet.ParametersJson = JsonConvert.SerializeObject(map, JsonSettings);
		packet.Summary = string.Format(CultureInfo.InvariantCulture, "ext={0}, cmd={1}, inner={2}", extensionId, command, sequence);
		packet.DecodeSucceeded = true;
		packet.CanExport = true;
	}

	private static byte[] DecryptInner(int sequence, byte[] encrypted)
	{
		byte[] data = (byte[])encrypted.Clone();
		for (int block = data.Length / 4 - 1; block >= 0; block--)
		{
			int index = block * 4 + (block & 1);
			byte temporary = data[index];
			data[index] = data[index + 2];
			data[index + 2] = temporary;
		}
		int key = (int)(((uint)sequence & InnerMask) >> 2);
		byte[] keys =
		{
			(byte)((key >> 22) & 0xFF),
			(byte)((key >> 18) & 0xFF),
			(byte)((key >> 9) & 0xFF),
			(byte)((key >> 2) & 0xFF)
		};
		for (int i = 0; i < data.Length; i++)
		{
			data[i] ^= keys[i & 3];
		}
		return data;
	}

	private static byte[] EncryptInner(int sequence, byte[] plain)
	{
		byte[] data = (byte[])plain.Clone();
		int key = (int)(((uint)sequence & InnerMask) >> 2);
		byte[] keys =
		{
			(byte)((key >> 22) & 0xFF),
			(byte)((key >> 18) & 0xFF),
			(byte)((key >> 9) & 0xFF),
			(byte)((key >> 2) & 0xFF)
		};
		for (int index = 0; index < data.Length; index++)
		{
			data[index] ^= keys[index & 3];
		}
		for (int block = 0; block < data.Length / 4; block++)
		{
			int index = block * 4 + (block & 1);
			byte temporary = data[index];
			data[index] = data[index + 2];
			data[index + 2] = temporary;
		}
		return data;
	}

	private static byte[] Xor(byte[] frame, int offset, uint sequence)
	{
		byte[] result = new byte[frame.Length - offset];
		byte[] key =
		{
			(byte)(sequence >> 24),
			(byte)(sequence >> 16),
			(byte)(sequence >> 8),
			(byte)sequence
		};
		for (int i = 0; i < result.Length; i++)
		{
			result[i] = (byte)(frame[offset + i] ^ key[i & 3]);
		}
		return result;
	}

	private static string ReadUtf(byte[] data, ref int position)
	{
		int length = ReadUInt16(data, position);
		position += 2;
		if (position + length > data.Length)
		{
			throw new InvalidOperationException("UTF 字段越界");
		}
		string value = Encoding.UTF8.GetString(data, position, length);
		position += length;
		return value;
	}

	private static void WriteUtf(List<byte> destination, string value)
	{
		byte[] bytes = Encoding.UTF8.GetBytes(value ?? string.Empty);
		if (bytes.Length > ushort.MaxValue)
		{
			throw new InvalidOperationException("UTF 字段过长");
		}
		WriteUInt16(destination, unchecked((ushort)bytes.Length));
		destination.AddRange(bytes);
	}

	private static void WriteUInt16(List<byte> destination, ushort value)
	{
		destination.Add((byte)(value >> 8));
		destination.Add((byte)value);
	}

	private static void WriteUInt32(List<byte> destination, uint value)
	{
		destination.Add((byte)(value >> 24));
		destination.Add((byte)(value >> 16));
		destination.Add((byte)(value >> 8));
		destination.Add((byte)value);
	}

	private static AolaPacketEvent NewPacket(long socket, int processId, string direction, byte[] frame)
	{
		return new AolaPacketEvent
		{
			TimestampUtc = DateTime.UtcNow,
			ProcessId = processId,
			SocketHandle = socket,
			Direction = direction,
			FrameLength = frame?.Length ?? 0,
			RawHex = frame == null ? string.Empty : BitConverter.ToString(frame).Replace("-", " ").ToLowerInvariant()
		};
	}

	private static string ToHex(byte[] data)
	{
		return data == null ? string.Empty : BitConverter.ToString(data).Replace("-", " ").ToLowerInvariant();
	}

	internal static ushort ReadUInt16(byte[] data, int offset)
	{
		if (data == null || offset < 0 || offset + 2 > data.Length)
		{
			throw new InvalidOperationException("读取 UInt16 越界");
		}
		return (ushort)((data[offset] << 8) | data[offset + 1]);
	}

	internal static uint ReadUInt32(byte[] data, int offset)
	{
		if (data == null || offset < 0 || offset + 4 > data.Length)
		{
			throw new InvalidOperationException("读取 UInt32 越界");
		}
		return ((uint)data[offset] << 24) | ((uint)data[offset + 1] << 16) | ((uint)data[offset + 2] << 8) | data[offset + 3];
	}
}
