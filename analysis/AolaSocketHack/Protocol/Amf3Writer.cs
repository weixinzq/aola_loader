// 架构角色：将受支持 CLR/JSON 值编码为 AMF3，供构造受控扩展消息使用。
// 数据流：参数对象 -> AMF3 byte[]；不负责外层帧和序列加密。
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Protocol;

internal sealed class Amf3Writer
{
	private const byte NullType = 1;
	private const byte FalseType = 2;
	private const byte TrueType = 3;
	private const byte IntegerType = 4;
	private const byte DoubleType = 5;
	private const byte StringType = 6;
	private const byte ArrayType = 9;
	private const byte ObjectType = 10;
	private const byte ByteArrayType = 12;
	private readonly List<byte> _buffer = new List<byte>();
	private readonly Dictionary<string, int> _strings = new Dictionary<string, int>(StringComparer.Ordinal);

	public byte[] ToArray()
	{
		return _buffer.ToArray();
	}

	public void WriteObject(object value)
	{
		if (value == null || value is JValue nullValue && nullValue.Type == JTokenType.Null)
		{
			WriteByte(NullType);
			return;
		}
		if (value is JToken token)
		{
			WriteToken(token);
			return;
		}
		if (value is bool boolean)
		{
			WriteByte(boolean ? TrueType : FalseType);
			return;
		}
		if (value is byte[] bytes)
		{
			WriteByteArray(bytes);
			return;
		}
		if (value is string text)
		{
			WriteString(text);
			return;
		}
		if (value is IDictionary<string, object> map)
		{
			WriteMap(map);
			return;
		}
		if (value is int || value is short || value is sbyte || value is byte || value is ushort)
		{
			WriteInteger(Convert.ToInt64(value, CultureInfo.InvariantCulture));
			return;
		}
		if (value is long || value is uint || value is ulong)
		{
			WriteInteger(Convert.ToInt64(value, CultureInfo.InvariantCulture));
			return;
		}
		if (value is float || value is double || value is decimal)
		{
			WriteDouble(Convert.ToDouble(value, CultureInfo.InvariantCulture));
			return;
		}
		WriteByte(NullType);
	}

	private void WriteToken(JToken token)
	{
		switch (token.Type)
		{
			case JTokenType.Object:
				WriteMap((JObject)token);
				break;
			case JTokenType.Array:
				WriteArray((JArray)token);
				break;
			case JTokenType.Integer:
				WriteInteger(token.Value<long>());
				break;
			case JTokenType.Float:
				WriteDouble(token.Value<double>());
				break;
			case JTokenType.Boolean:
				WriteByte(token.Value<bool>() ? TrueType : FalseType);
				break;
			case JTokenType.String:
				WriteString(token.Value<string>() ?? string.Empty);
				break;
			case JTokenType.Bytes:
				WriteByteArray(token.Value<byte[]>() ?? Array.Empty<byte>());
				break;
			default:
				WriteByte(NullType);
				break;
		}
	}

	private void WriteInteger(long value)
	{
		if (value >= -268435456L && value <= 268435455L)
		{
			WriteByte(IntegerType);
			WriteU29(unchecked((uint)value) & 0x1FFFFFFF);
		}
		else
		{
			WriteDouble(value);
		}
	}

	private void WriteDouble(double value)
	{
		WriteByte(DoubleType);
		byte[] bytes = BitConverter.GetBytes(value);
		if (BitConverter.IsLittleEndian)
		{
			Array.Reverse(bytes);
		}
		_buffer.AddRange(bytes);
	}

	private void WriteString(string value)
	{
		WriteByte(StringType);
		WriteStringWithoutType(value);
	}

	private void WriteStringWithoutType(string value)
	{
		value = value ?? string.Empty;
		if (value.Length == 0)
		{
			WriteU29(1);
			return;
		}
		if (_strings.TryGetValue(value, out int reference))
		{
			WriteU29(unchecked((uint)(reference << 1)));
			return;
		}
		_strings[value] = _strings.Count;
		byte[] bytes = Encoding.UTF8.GetBytes(value);
		WriteU29(unchecked((uint)((bytes.Length << 1) | 1)));
		_buffer.AddRange(bytes);
	}

	private void WriteMap(JObject map)
	{
		WriteByte(ObjectType);
		WriteU29(11);
		WriteStringWithoutType(string.Empty);
		foreach (JProperty property in map.Properties())
		{
			WriteStringWithoutType(property.Name);
			WriteObject(property.Value);
		}
		WriteStringWithoutType(string.Empty);
	}

	private void WriteMap(IDictionary<string, object> map)
	{
		WriteByte(ObjectType);
		WriteU29(11);
		WriteStringWithoutType(string.Empty);
		foreach (KeyValuePair<string, object> property in map)
		{
			WriteStringWithoutType(property.Key);
			WriteObject(property.Value);
		}
		WriteStringWithoutType(string.Empty);
	}

	private void WriteArray(JArray array)
	{
		WriteByte(ArrayType);
		WriteU29(unchecked((uint)((array.Count << 1) | 1)));
		WriteStringWithoutType(string.Empty);
		foreach (JToken item in array)
		{
			WriteObject(item);
		}
	}

	private void WriteByteArray(byte[] value)
	{
		WriteByte(ByteArrayType);
		WriteU29(unchecked((uint)((value.Length << 1) | 1)));
		_buffer.AddRange(value);
	}

	private void WriteU29(uint value)
	{
		value &= 0x3FFFFFFF;
		if (value < 128)
		{
			WriteByte((byte)value);
		}
		else if (value < 16384)
		{
			WriteByte((byte)(((value >> 7) & 0x7F) | 0x80));
			WriteByte((byte)(value & 0x7F));
		}
		else if (value < 2097152)
		{
			WriteByte((byte)(((value >> 14) & 0x7F) | 0x80));
			WriteByte((byte)(((value >> 7) & 0x7F) | 0x80));
			WriteByte((byte)(value & 0x7F));
		}
		else
		{
			WriteByte((byte)(((value >> 22) & 0x7F) | 0x80));
			WriteByte((byte)(((value >> 15) & 0x7F) | 0x80));
			WriteByte((byte)(((value >> 8) & 0x7F) | 0x80));
			WriteByte((byte)(value & 0xFF));
		}
	}

	private void WriteByte(byte value)
	{
		_buffer.Add(value);
	}
}
