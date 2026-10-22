using System.Text;
using AolaSocketHack.Protocol;
using Newtonsoft.Json.Linq;

namespace AolaTestServer;

internal static class ServerFrames
{
	public static byte[] Extension(JObject data)
	{
		var writer = new Amf3Writer();
		writer.WriteObject(data);
		return Frame(new byte[] { 1 }.Concat(writer.ToArray()).ToArray());
	}

	public static byte[] System(int action, int roomId, Action<BinaryWriter> payload)
	{
		using var body = new MemoryStream();
		using var writer = new BinaryWriter(body, Encoding.UTF8, true);
		writer.Write((byte)0);
		Int16(writer, action);
		Int32(writer, roomId);
		payload(writer);
		return Frame(body.ToArray());
	}

	public static byte[] Frame(byte[] body)
	{
		using var stream = new MemoryStream();
		using var writer = new BinaryWriter(stream);
		Int32(writer, body.Length);
		writer.Write(body);
		return stream.ToArray();
	}

	public static void Int16(BinaryWriter writer, int value)
	{
		writer.Write((byte)(value >> 8));
		writer.Write((byte)value);
	}

	public static void Int32(BinaryWriter writer, int value)
	{
		writer.Write((byte)(value >> 24));
		writer.Write((byte)(value >> 16));
		writer.Write((byte)(value >> 8));
		writer.Write((byte)value);
	}

	public static void Utf(BinaryWriter writer, string value)
	{
		byte[] bytes = Encoding.UTF8.GetBytes(value);
		Int16(writer, bytes.Length);
		writer.Write(bytes);
	}

	public static void Variables(BinaryWriter writer, JObject values)
	{
		Int16(writer, values.Count);
		foreach (var item in values)
		{
			Utf(writer, item.Key);
			writer.Write((byte)(item.Value.Type == JTokenType.Integer || item.Value.Type == JTokenType.Float ? 'n' : item.Value.Type == JTokenType.Boolean ? 'b' : 's'));
			Utf(writer, item.Value.Type == JTokenType.Boolean ? ((bool)item.Value ? "1" : "0") : item.Value.ToString());
		}
	}
}
