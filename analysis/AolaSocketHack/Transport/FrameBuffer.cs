// 架构角色：有界 TCP 帧缓冲，处理半包、粘包、长度前缀和策略 XML 的消息边界。
// 数据流：任意字节块 -> 完整 frame/null-terminated payload 或等待更多数据。
using System;
using System.Collections.Generic;

namespace AolaSocketHack.Transport;

internal sealed class FrameBuffer
{
	private const int MaximumFrameLength = 4 * 1024 * 1024;
	private const int DefaultMaximumBufferedBytes = 16 * 1024 * 1024;
	private readonly List<byte> _bytes = new List<byte>();
	private readonly int _maximumBufferedBytes;

	public FrameBuffer(int maximumBufferedBytes = DefaultMaximumBufferedBytes)
	{
		if (maximumBufferedBytes <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumBufferedBytes));
		}
		_maximumBufferedBytes = maximumBufferedBytes;
	}

	public int Count => _bytes.Count;

	public bool TryAppend(byte[] bytes)
	{
		if (bytes == null || bytes.Length == 0)
		{
			return true;
		}
		if (bytes.Length > _maximumBufferedBytes - _bytes.Count)
		{
			Clear();
			return false;
		}
		_bytes.AddRange(bytes);
		return true;
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

	public bool TryTakeNullTerminated(int maximumLength, out byte[] value, out bool exceededLimit)
	{
		if (maximumLength <= 0)
		{
			throw new ArgumentOutOfRangeException(nameof(maximumLength));
		}
		exceededLimit = false;
		int index = _bytes.IndexOf(0);
		if (index < 0)
		{
			if (_bytes.Count > maximumLength)
			{
				exceededLimit = true;
				Clear();
			}
			value = null;
			return false;
		}
		if (index + 1 > maximumLength)
		{
			exceededLimit = true;
			Clear();
			value = null;
			return false;
		}
		value = _bytes.GetRange(0, index + 1).ToArray();
		_bytes.RemoveRange(0, index + 1);
		return true;
	}

	public bool TryTakeFrame(out byte[] frame, out bool invalidLength)
	{
		frame = null;
		invalidLength = false;
		if (_bytes.Count < 4)
		{
			return false;
		}
		uint length = ((uint)_bytes[0] << 24) | ((uint)_bytes[1] << 16) | ((uint)_bytes[2] << 8) | _bytes[3];
		if (length == 0 || length > MaximumFrameLength)
		{
			invalidLength = true;
			Clear();
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

	public void Clear()
	{
		for (int index = 0; index < _bytes.Count; index++)
		{
			_bytes[index] = 0;
		}
		_bytes.Clear();
	}
}
