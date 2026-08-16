using System;
using System.Collections.Generic;

namespace AolaSocketHack.Transport;

internal sealed class FrameBuffer
{
	private const int MaximumFrameLength = 4 * 1024 * 1024;
	private readonly List<byte> _bytes = new List<byte>();

	public int Count => _bytes.Count;

	public void Append(byte[] bytes)
	{
		if (bytes != null && bytes.Length != 0)
		{
			_bytes.AddRange(bytes);
		}
	}

	public bool StartsWith(byte[] prefix)
	{
		if (prefix == null || _bytes.Count < prefix.Length)
		{
			return false;
		}
		for (int i = 0; i < prefix.Length; i++)
		{
			if (_bytes[i] != prefix[i])
			{
				return false;
			}
		}
		return true;
	}

	public bool CouldStartWith(byte[] prefix)
	{
		if (prefix == null || prefix.Length == 0 || _bytes.Count == 0)
		{
			return false;
		}
		int count = Math.Min(prefix.Length, _bytes.Count);
		for (int i = 0; i < count; i++)
		{
			if (_bytes[i] != prefix[i])
			{
				return false;
			}
		}
		return true;
	}

	public bool TryTakeNullTerminated(out byte[] value)
	{
		int index = _bytes.IndexOf(0);
		if (index < 0)
		{
			value = null;
			return false;
		}
		value = _bytes.GetRange(0, index + 1).ToArray();
		_bytes.RemoveRange(0, index + 1);
		return true;
	}

	public bool TryTakeFrame(out byte[] frame)
	{
		frame = null;
		if (_bytes.Count < 4)
		{
			return false;
		}
		uint length = ((uint)_bytes[0] << 24) | ((uint)_bytes[1] << 16) | ((uint)_bytes[2] << 8) | _bytes[3];
		if (length == 0 || length > MaximumFrameLength)
		{
			_bytes.Clear();
			return false;
		}
		long total = 4L + length;
		if (_bytes.Count < total)
		{
			return false;
		}
		frame = _bytes.GetRange(0, (int)total).ToArray();
		_bytes.RemoveRange(0, (int)total);
		return true;
	}
}
