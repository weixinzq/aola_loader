using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Text;
using AolaLoader.ResourceInterception.Pipeline;

namespace AolaLoader;

internal static class AolaSwfBitmapScaler
{
	private const int DefineBitsLossless2Tag = 36;
	private const int SymbolClassTag = 76;
	private const int DoAbcTag = 82;
	private const int DefineBinaryDataTag = 87;
	private const int MaximumOutputBytes = 64 * 1024 * 1024;
	private const int MaximumBitmapBytes = 128 * 1024 * 1024;

	public static bool TryScaleFws(byte[] content, double factor, out byte[] scaled)
	{
		scaled = null;
		if (!SwfResponseHeaderValidator.IsValidCompleteFws(content) ||
			double.IsNaN(factor) || double.IsInfinity(factor) || factor <= 0.1 || factor > 10)
		{
			return false;
		}
		if (Math.Abs(factor - 1) < 0.0001)
		{
			scaled = (byte[])content.Clone();
			return true;
		}

		int tagOffset = GetTagOffset(content);
		if (tagOffset < 0)
		{
			return false;
		}

		List<SwfTag> tags = ParseTags(content, tagOffset);
		if (tags == null)
		{
			return false;
		}

		Dictionary<int, int> dimensions = new Dictionary<int, int>();
		bool scaledBitmap = false;
		foreach (SwfTag tag in tags)
		{
			if (tag.Code != DefineBitsLossless2Tag)
			{
				continue;
			}
			if (!TryScaleLosslessBitmap(tag.Body, factor, dimensions, out byte[] body))
			{
				return false;
			}
			tag.Body = body;
			scaledBitmap = true;
		}
		if (!scaledBitmap || dimensions.Count == 0)
		{
			return false;
		}

		foreach (SwfTag tag in tags)
		{
			if (tag.Code == DefineBinaryDataTag && TryScaleMovieConfig(tag.Body, factor, out byte[] configBody))
			{
				tag.Body = configBody;
			}
			else if (tag.Code == DoAbcTag)
			{
				if (!TryPatchAbcDimensions(tag.Body, dimensions, out byte[] abcBody))
				{
					return false;
				}
				tag.Body = abcBody;
			}
		}

		using (MemoryStream output = new MemoryStream())
		{
			output.Write(content, 0, tagOffset);
			foreach (SwfTag tag in tags)
			{
				WriteTag(output, tag);
				if (output.Length > MaximumOutputBytes)
				{
					return false;
				}
			}
			scaled = output.ToArray();
		}
		WriteUInt32(scaled, 4, (uint)scaled.Length);
		return scaled.Length <= MaximumOutputBytes &&
			scaled[0] == 'F' && scaled[1] == 'W' && scaled[2] == 'S';
	}

	public static bool TryMakeTransparentFws(byte[] content, out byte[] transparent)
	{
		transparent = null;
		if (!SwfResponseHeaderValidator.IsValidCompleteFws(content))
		{
			return false;
		}

		int tagOffset = GetTagOffset(content);
		if (tagOffset < 0)
		{
			return false;
		}
		List<SwfTag> tags = ParseTags(content, tagOffset);
		if (tags == null)
		{
			return false;
		}

		int hiddenBitmapCount = 0;
		foreach (SwfTag tag in tags)
		{
			if (tag.Code != DefineBitsLossless2Tag)
			{
				continue;
			}
			if (!TryMakeLosslessBitmapTransparent(tag.Body, out byte[] body))
			{
				return false;
			}
			tag.Body = body;
			hiddenBitmapCount++;
		}
		if (hiddenBitmapCount == 0)
		{
			return false;
		}

		using (MemoryStream output = new MemoryStream())
		{
			output.Write(content, 0, tagOffset);
			foreach (SwfTag tag in tags)
			{
				WriteTag(output, tag);
				if (output.Length > MaximumOutputBytes)
				{
					return false;
				}
			}
			transparent = output.ToArray();
		}
		WriteUInt32(transparent, 4, (uint)transparent.Length);
		return SwfResponseHeaderValidator.IsValidCompleteFws(transparent);
	}

	private static bool TryMakeLosslessBitmapTransparent(byte[] body, out byte[] transparentBody)
	{
		transparentBody = null;
		if (body == null || body.Length < 8 || body[2] != 3 && body[2] != 5)
		{
			return false;
		}

		int format = body[2];
		int width = ReadUInt16(body, 3);
		int height = ReadUInt16(body, 5);
		if (width <= 0 || height <= 0)
		{
			return false;
		}
		int dataOffset = format == 3 ? 8 : 7;
		int paletteEntries = format == 3 ? body[7] + 1 : 0;
		int paletteBytes = paletteEntries * 4;
		int stride = format == 3 ? (width + 3) & ~3 : checked(width * 4);
		int decodedLength = checked(paletteBytes + stride * height);
		byte[] compressed = new byte[body.Length - dataOffset];
		Buffer.BlockCopy(body, dataOffset, compressed, 0, compressed.Length);
		if (!TryDecompressZlib(compressed, decodedLength, out byte[] pixels))
		{
			return false;
		}

		if (format == 3)
		{
			for (int index = 0; index < paletteEntries; index++)
			{
				// Lossless2 colormaps store RGBA palette entries.
				pixels[index * 4 + 3] = 0;
			}
		}
		else
		{
			for (int y = 0; y < height; y++)
			{
				for (int x = 0; x < width; x++)
				{
					// Lossless2 format 5 stores pixels as ARGB.
					pixels[y * stride + x * 4] = 0;
				}
			}
		}

		byte[] transparentCompressed = CompressZlib(pixels);
		transparentBody = new byte[dataOffset + transparentCompressed.Length];
		Buffer.BlockCopy(body, 0, transparentBody, 0, dataOffset);
		Buffer.BlockCopy(transparentCompressed, 0, transparentBody, dataOffset,
			transparentCompressed.Length);
		return true;
	}

	private static int GetTagOffset(byte[] content)
	{
		if (content.Length < 13)
		{
			return -1;
		}
		int nbits = content[8] >> 3;
		int rectBytes = (5 + nbits * 4 + 7) / 8;
		int offset = 8 + rectBytes + 4;
		return offset <= content.Length ? offset : -1;
	}

	private static List<SwfTag> ParseTags(byte[] content, int offset)
	{
		List<SwfTag> tags = new List<SwfTag>();
		while (offset < content.Length)
		{
			if (offset + 2 > content.Length)
			{
				return null;
			}
			ushort header = ReadUInt16(content, offset);
			offset += 2;
			int code = header >> 6;
			long length = header & 0x3f;
			if (length == 0x3f)
			{
				if (offset + 4 > content.Length)
				{
					return null;
				}
				length = ReadUInt32(content, offset);
				offset += 4;
			}
			if (length < 0 || length > int.MaxValue || offset + length > content.Length)
			{
				return null;
			}
			byte[] body = new byte[(int)length];
			Buffer.BlockCopy(content, offset, body, 0, body.Length);
			offset += body.Length;
			tags.Add(new SwfTag(code, body));
			if (code == 0)
			{
				return offset == content.Length ? tags : null;
			}
		}
		return null;
	}

	private static bool TryScaleLosslessBitmap(
		byte[] body,
		double factor,
		Dictionary<int, int> dimensions,
		out byte[] scaledBody)
	{
		scaledBody = null;
		if (body.Length < 8 || body[2] != 3 && body[2] != 5)
		{
			return false;
		}
		int format = body[2];
		int width = ReadUInt16(body, 3);
		int height = ReadUInt16(body, 5);
		int scaledWidth = ScaleDimension(width, factor);
		int scaledHeight = ScaleDimension(height, factor);
		if (width <= 0 || height <= 0 || scaledWidth <= 0 || scaledHeight <= 0 ||
			scaledWidth > ushort.MaxValue || scaledHeight > ushort.MaxValue)
		{
			return false;
		}

		int dataOffset = format == 3 ? 8 : 7;
		int paletteBytes = format == 3 ? (body[7] + 1) * 4 : 0;
		int sourceStride = format == 3 ? (width + 3) & ~3 : checked(width * 4);
		int scaledStride = format == 3 ? (scaledWidth + 3) & ~3 : checked(scaledWidth * 4);
		int sourceLength = checked(paletteBytes + sourceStride * height);
		long scaledLength = (long)paletteBytes + (long)scaledStride * scaledHeight;
		byte[] compressed = new byte[body.Length - dataOffset];
		Buffer.BlockCopy(body, dataOffset, compressed, 0, compressed.Length);
		if (!TryDecompressZlib(compressed, sourceLength, out byte[] pixels))
		{
			return false;
		}
		if (scaledLength > MaximumBitmapBytes)
		{
			return false;
		}
		byte[] scaledPixels = new byte[(int)scaledLength];
		if (paletteBytes > 0)
		{
			Buffer.BlockCopy(pixels, 0, scaledPixels, 0, paletteBytes);
		}
		for (int y = 0; y < scaledHeight; y++)
		{
			int sourceY = (int)((long)y * height / scaledHeight);
			for (int x = 0; x < scaledWidth; x++)
			{
				int sourceX = (int)((long)x * width / scaledWidth);
				int pixelBytes = format == 3 ? 1 : 4;
				Buffer.BlockCopy(
					pixels,
					paletteBytes + sourceY * sourceStride + sourceX * pixelBytes,
					scaledPixels,
					paletteBytes + y * scaledStride + x * pixelBytes,
					pixelBytes);
			}
		}

		byte[] scaledCompressed = CompressZlib(scaledPixels);
		scaledBody = new byte[dataOffset + scaledCompressed.Length];
		Buffer.BlockCopy(body, 0, scaledBody, 0, dataOffset);
		WriteUInt16(scaledBody, 3, (ushort)scaledWidth);
		WriteUInt16(scaledBody, 5, (ushort)scaledHeight);
		Buffer.BlockCopy(scaledCompressed, 0, scaledBody, dataOffset, scaledCompressed.Length);
		dimensions[width] = scaledWidth;
		dimensions[height] = scaledHeight;
		return true;
	}

	private static bool TryScaleMovieConfig(byte[] body, double factor, out byte[] scaledBody)
	{
		scaledBody = null;
		if (body.Length <= 6)
		{
			return false;
		}
		string text = Encoding.ASCII.GetString(body, 6, body.Length - 6);
		string[] entries = text.Split(';');
		if (entries.Length == 0)
		{
			return false;
		}
		for (int index = 0; index < entries.Length; index++)
		{
			string[] values = entries[index].Split(',');
			if (values.Length != 3 ||
				!int.TryParse(values[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out int frame) ||
				!int.TryParse(values[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out int x) ||
				!int.TryParse(values[2], NumberStyles.Integer, CultureInfo.InvariantCulture, out int y))
			{
				return false;
			}
			entries[index] = frame.ToString(CultureInfo.InvariantCulture) + "," +
				ScaleCoordinate(x, factor).ToString(CultureInfo.InvariantCulture) + "," +
				ScaleCoordinate(y, factor).ToString(CultureInfo.InvariantCulture);
		}
		byte[] data = Encoding.ASCII.GetBytes(string.Join(";", entries));
		scaledBody = new byte[6 + data.Length];
		Buffer.BlockCopy(body, 0, scaledBody, 0, 6);
		Buffer.BlockCopy(data, 0, scaledBody, 6, data.Length);
		return true;
	}

	private static bool TryPatchAbcDimensions(
		byte[] body,
		Dictionary<int, int> dimensions,
		out byte[] patchedBody)
	{
		patchedBody = null;
		if (body.Length < 9)
		{
			return false;
		}
		int nameEnd = Array.IndexOf(body, (byte)0, 4);
		if (nameEnd < 0 || nameEnd + 5 > body.Length)
		{
			return false;
		}
		int cursor = nameEnd + 5;
		int intCountStart = cursor;
		if (!TryReadU30(body, ref cursor, out uint intCount))
		{
			return false;
		}

		using (MemoryStream output = new MemoryStream())
		{
			output.Write(body, 0, cursor);
			for (uint index = 1; index < intCount; index++)
			{
				int valueStart = cursor;
				if (!TryReadU30(body, ref cursor, out uint value))
				{
					return false;
				}
				if (value <= int.MaxValue && dimensions.TryGetValue((int)value, out int replacement))
				{
					WriteU30(output, (uint)replacement);
				}
				else
				{
					output.Write(body, valueStart, cursor - valueStart);
				}
			}
			output.Write(body, cursor, body.Length - cursor);
			patchedBody = output.ToArray();
		}
		return intCountStart < body.Length;
	}

	private static bool TryDecompressZlib(byte[] content, int expectedLength, out byte[] decoded)
	{
		decoded = null;
		if (content.Length < 6 || expectedLength < 0 || expectedLength > MaximumBitmapBytes)
		{
			return false;
		}
		ushort header = (ushort)((content[0] << 8) | content[1]);
		if ((content[0] & 0x0f) != 8 || header % 31 != 0 || (content[1] & 0x20) != 0)
		{
			return false;
		}
		using (MemoryStream input = new MemoryStream(content, 2, content.Length - 6, false))
		using (DeflateStream deflate = new DeflateStream(input, CompressionMode.Decompress))
		using (MemoryStream output = new MemoryStream(expectedLength))
		{
			deflate.CopyTo(output);
			decoded = output.ToArray();
		}
		uint expectedAdler = ReadUInt32BigEndian(content, content.Length - 4);
		return decoded.Length == expectedLength && Adler32(decoded) == expectedAdler;
	}

	private static byte[] CompressZlib(byte[] content)
	{
		using (MemoryStream output = new MemoryStream())
		{
			output.WriteByte(0x78);
			output.WriteByte(0x9c);
			using (DeflateStream deflate = new DeflateStream(output, CompressionLevel.Optimal, true))
			{
				deflate.Write(content, 0, content.Length);
			}
			uint adler = Adler32(content);
			output.WriteByte((byte)(adler >> 24));
			output.WriteByte((byte)(adler >> 16));
			output.WriteByte((byte)(adler >> 8));
			output.WriteByte((byte)adler);
			return output.ToArray();
		}
	}

	private static uint Adler32(byte[] content)
	{
		const uint modulus = 65521;
		uint a = 1;
		uint b = 0;
		foreach (byte value in content)
		{
			a = (a + value) % modulus;
			b = (b + a) % modulus;
		}
		return b << 16 | a;
	}

	private static int ScaleDimension(int value, double factor)
	{
		return (int)Math.Round(value * factor, MidpointRounding.AwayFromZero);
	}

	private static int ScaleCoordinate(int value, double factor)
	{
		return (int)Math.Round(value * factor, MidpointRounding.AwayFromZero);
	}

	private static void WriteTag(Stream output, SwfTag tag)
	{
		int length = tag.Body.Length;
		ushort header = (ushort)(tag.Code << 6 | (length < 0x3f ? length : 0x3f));
		WriteUInt16(output, header);
		if (length >= 0x3f)
		{
			WriteUInt32(output, (uint)length);
		}
		output.Write(tag.Body, 0, tag.Body.Length);
	}

	private static bool TryReadU30(byte[] content, ref int offset, out uint value)
	{
		value = 0;
		for (int index = 0; index < 5; index++)
		{
			if (offset >= content.Length)
			{
				return false;
			}
			byte current = content[offset++];
			value |= (uint)(current & 0x7f) << index * 7;
			if ((current & 0x80) == 0)
			{
				return value <= 0x3fffffff;
			}
		}
		return false;
	}

	private static void WriteU30(Stream output, uint value)
	{
		do
		{
			byte current = (byte)(value & 0x7f);
			value >>= 7;
			if (value != 0)
			{
				current |= 0x80;
			}
			output.WriteByte(current);
		}
		while (value != 0);
	}

	private static ushort ReadUInt16(byte[] content, int offset)
	{
		return (ushort)(content[offset] | content[offset + 1] << 8);
	}

	private static uint ReadUInt32(byte[] content, int offset)
	{
		return (uint)(content[offset] |
			content[offset + 1] << 8 |
			content[offset + 2] << 16 |
			content[offset + 3] << 24);
	}

	private static uint ReadUInt32BigEndian(byte[] content, int offset)
	{
		return (uint)(content[offset] << 24 |
			content[offset + 1] << 16 |
			content[offset + 2] << 8 |
			content[offset + 3]);
	}

	private static void WriteUInt16(byte[] content, int offset, ushort value)
	{
		content[offset] = (byte)value;
		content[offset + 1] = (byte)(value >> 8);
	}

	private static void WriteUInt32(byte[] content, int offset, uint value)
	{
		content[offset] = (byte)value;
		content[offset + 1] = (byte)(value >> 8);
		content[offset + 2] = (byte)(value >> 16);
		content[offset + 3] = (byte)(value >> 24);
	}

	private static void WriteUInt16(Stream output, ushort value)
	{
		output.WriteByte((byte)value);
		output.WriteByte((byte)(value >> 8));
	}

	private static void WriteUInt32(Stream output, uint value)
	{
		output.WriteByte((byte)value);
		output.WriteByte((byte)(value >> 8));
		output.WriteByte((byte)(value >> 16));
		output.WriteByte((byte)(value >> 24));
	}

	private sealed class SwfTag
	{
		public SwfTag(int code, byte[] body)
		{
			Code = code;
			Body = body;
		}

		public int Code { get; }
		public byte[] Body { get; set; }
	}
}
