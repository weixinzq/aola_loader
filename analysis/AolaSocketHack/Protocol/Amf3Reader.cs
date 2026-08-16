using System;
using System.Collections.Generic;
using System.Text;

namespace AolaSocketHack.Protocol;

internal sealed class Amf3Reader
{
	private readonly byte[] _data;
	private readonly List<object> _objects = new List<object>();
	private readonly List<string> _strings = new List<string>();
	private readonly List<TraitsInfo> _traits = new List<TraitsInfo>();
	private int _position;

	public Amf3Reader(byte[] data, int offset = 0)
	{
		_data = data ?? throw new ArgumentNullException(nameof(data));
		_position = offset;
	}

	public object ReadObject()
	{
		return ReadObjectValue(ReadByte());
	}

	private object ReadObjectValue(int type)
	{
		switch (type)
		{
		case 0:
		case 1:
			return null;
		case 2:
			return false;
		case 3:
			return true;
		case 4:
		{
			int value = ReadU29();
			return value >= 0x10000000 ? value - 0x20000000 : value;
		}
		case 5:
			return ReadDouble();
		case 6:
			return ReadString();
		case 9:
			return ReadArray();
		case 10:
			return ReadScriptObject();
		case 12:
			return ReadByteArray();
		default:
			throw new InvalidOperationException("Unsupported AMF3 type: " + type);
		}
	}

	private object ReadArray()
	{
		int reference = ReadU29();
		if ((reference & 1) == 0)
		{
			return GetReference(_objects, reference >> 1, "object");
		}

		int count = reference >> 1;
		string key = ReadString();
		if (key.Length == 0)
		{
			List<object> values = new List<object>(count);
			_objects.Add(values);
			for (int i = 0; i < count; i++)
			{
				values.Add(ReadObject());
			}
			return values;
		}

		Dictionary<string, object> map = new Dictionary<string, object>();
		_objects.Add(map);
		while (key.Length != 0)
		{
			map[key] = ReadObject();
			key = ReadString();
		}
		for (int i = 0; i < count; i++)
		{
			map[i.ToString()] = ReadObject();
		}
		return map;
	}

	private object ReadScriptObject()
	{
		int reference = ReadU29();
		if ((reference & 1) == 0)
		{
			return GetReference(_objects, reference >> 1, "object");
		}

		TraitsInfo traits = ReadTraits(reference);
		Dictionary<string, object> result = new Dictionary<string, object>();
		_objects.Add(result);
		if (traits.Externalizable)
		{
			object external = ReadObject();
			return external ?? result;
		}

		foreach (string property in traits.Properties)
		{
			result[property] = ReadObject();
		}
		if (traits.Dynamic)
		{
			while (true)
			{
				string name = ReadString();
				if (name.Length == 0)
				{
					break;
				}
				result[name] = ReadObject();
			}
		}
		return result;
	}

	private byte[] ReadByteArray()
	{
		int reference = ReadU29();
		if ((reference & 1) == 0)
		{
			return (byte[])GetReference(_objects, reference >> 1, "byte array");
		}
		int length = reference >> 1;
		byte[] value = ReadBytes(length);
		_objects.Add(value);
		return value;
	}

	private TraitsInfo ReadTraits(int reference)
	{
		if ((reference & 3) == 1)
		{
			return GetReference(_traits, reference >> 2, "traits");
		}

		TraitsInfo traits = new TraitsInfo
		{
			Externalizable = (reference & 4) != 0,
			Dynamic = (reference & 8) != 0
		};
		int count = reference >> 4;
		ReadString(); // class name; not needed for packet display
		_traits.Add(traits);
		for (int i = 0; i < count; i++)
		{
			traits.Properties.Add(ReadString());
		}
		return traits;
	}

	private string ReadString()
	{
		int reference = ReadU29();
		if ((reference & 1) == 0)
		{
			return GetReference(_strings, reference >> 1, "string");
		}
		int length = reference >> 1;
		if (length == 0)
		{
			return string.Empty;
		}
		string value = Encoding.UTF8.GetString(ReadBytes(length));
		_strings.Add(value);
		return value;
	}

	private int ReadU29()
	{
		int b = ReadByte();
		if (b < 128)
		{
			return b;
		}
		int value = (b & 0x7F) << 7;
		b = ReadByte();
		if (b < 128)
		{
			return value | b;
		}
		value = (value | (b & 0x7F)) << 7;
		b = ReadByte();
		if (b < 128)
		{
			return value | b;
		}
		value = (value | (b & 0x7F)) << 8;
		return value | ReadByte();
	}

	private double ReadDouble()
	{
		byte[] raw = ReadBytes(8);
		if (BitConverter.IsLittleEndian)
		{
			Array.Reverse(raw);
		}
		return BitConverter.ToDouble(raw, 0);
	}

	private int ReadByte()
	{
		if (_position >= _data.Length)
		{
			throw new InvalidOperationException("Unexpected AMF3 end of data");
		}
		return _data[_position++];
	}

	private byte[] ReadBytes(int length)
	{
		if (length < 0 || _position + length > _data.Length)
		{
			throw new InvalidOperationException("Unexpected AMF3 end of data");
		}
		byte[] result = new byte[length];
		Buffer.BlockCopy(_data, _position, result, 0, length);
		_position += length;
		return result;
	}

	private static T GetReference<T>(IList<T> values, int index, string kind)
	{
		if (index < 0 || index >= values.Count)
		{
			throw new InvalidOperationException("Invalid AMF3 " + kind + " reference: " + index);
		}
		return values[index];
	}

	private sealed class TraitsInfo
	{
		public bool Dynamic { get; set; }

		public bool Externalizable { get; set; }

		public List<string> Properties { get; } = new List<string>();
	}
}
