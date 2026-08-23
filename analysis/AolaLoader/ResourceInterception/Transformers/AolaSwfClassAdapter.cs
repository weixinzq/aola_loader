using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;
using SharpCompress.Compressors.LZMA;

namespace AolaLoader.ResourceInterception.Transformers;

internal static class AolaSwfClassAdapter
{
	private const int DoAbcTag = 82;
	private const int ExportAssetsTag = 56;
	private const int SymbolClassTag = 76;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private const int MaximumLzmaDictionaryBytes = 64 * 1024 * 1024;

	public static bool TryAdapt(
		byte[] content,
		string sourceToken,
		string targetToken,
		out byte[] adapted)
	{
		adapted = null;
		if (string.IsNullOrEmpty(sourceToken) || string.IsNullOrEmpty(targetToken) ||
			!TryDecodeToFws(content, out byte[] fws))
		{
			return false;
		}

		string sourceClass = "mmo.petskin.view." + sourceToken;
		string targetClass = "mmo.petskin.view." + targetToken;
		int tagOffset = GetTagOffset(fws);
		if (tagOffset < 0 || !TryParseTags(fws, tagOffset, out List<SwfTag> tags))
		{
			return false;
		}

		int targetMatches = 0;
		int sourceMatches = 0;
		foreach (SwfTag tag in tags)
		{
			if (tag.Code == SymbolClassTag || tag.Code == ExportAssetsTag)
			{
				if (!TryPatchClassNameTag(tag.Body, sourceClass, targetClass, ref sourceMatches, ref targetMatches,
					out byte[] patchedBody))
				{
					return false;
				}
				tag.Body = patchedBody;
			}
			else if (tag.Code == DoAbcTag)
			{
				if (!TryPatchDoAbc(tag.Body, sourceToken, targetToken, sourceClass, targetClass,
					ref sourceMatches, ref targetMatches, out byte[] patchedBody))
				{
					return false;
				}
				tag.Body = patchedBody;
			}
		}

		// Exactly one side must be present. A source-only response is the normal
		// server response; a target-only response was already adapted in memory or
		// came from a CEF cache. Seeing both sides is ambiguous and is rejected.
		if ((targetMatches == 0) == (sourceMatches == 0) ||
			(targetMatches > 0 && sourceMatches > 0))
		{
			return false;
		}

		using (MemoryStream output = new MemoryStream())
		{
			output.Write(fws, 0, tagOffset);
			foreach (SwfTag tag in tags)
			{
				WriteTag(output, tag);
				if (output.Length > MaximumSwfBytes)
				{
					return false;
				}
			}
			adapted = output.ToArray();
		}
		WriteUInt32(adapted, 4, (uint)adapted.Length);
		return IsValidFws(adapted);
	}

	internal static bool TryDecodeToFws(byte[] content, out byte[] fws)
	{
		fws = null;
		if (content == null || content.Length < 8 || content.Length > MaximumSwfBytes)
		{
			return false;
		}
		uint declaredLength = ReadUInt32(content, 4);
		if (declaredLength < 8 || declaredLength > MaximumSwfBytes)
		{
			return false;
		}
		if (content[0] == 'F' && content[1] == 'W' && content[2] == 'S')
		{
			if (declaredLength != content.Length)
			{
				return false;
			}
			fws = (byte[])content.Clone();
			return true;
		}
		if (content[0] == 'Z' && content[1] == 'W' && content[2] == 'S')
		{
			return TryDecodeZwsToFws(content, declaredLength, out fws);
		}
		if (content[0] != 'C' || content[1] != 'W' || content[2] != 'S')
		{
			return false;
		}
		try
		{
			using (MemoryStream input = new MemoryStream(content, 8, content.Length - 8, false))
			using (DeflateStream deflate = new DeflateStream(input, CompressionMode.Decompress))
			using (MemoryStream body = new MemoryStream((int)declaredLength - 8))
			{
				deflate.CopyTo(body);
				if (body.Length + 8 != declaredLength || body.Length + 8 > MaximumSwfBytes)
				{
					return false;
				}
				fws = new byte[body.Length + 8];
				fws[0] = (byte)'F';
				fws[1] = (byte)'W';
				fws[2] = (byte)'S';
				fws[3] = content[3];
				WriteUInt32(fws, 4, declaredLength);
				Buffer.BlockCopy(body.GetBuffer(), 0, fws, 8, (int)body.Length);
				return true;
			}
		}
		catch (InvalidDataException)
		{
			return false;
		}
		catch (IOException)
		{
			return false;
		}
	}

	private static bool TryDecodeZwsToFws(byte[] content, uint declaredLength, out byte[] fws)
	{
		fws = null;
		if (content.Length < 17)
		{
			return false;
		}
		uint compressedLength = ReadUInt32(content, 8);
		uint dictionarySize = ReadUInt32(content, 13);
		if (compressedLength != content.Length - 17 || dictionarySize == 0 ||
			dictionarySize > MaximumLzmaDictionaryBytes)
		{
			return false;
		}

		byte propertiesValue = content[12];
		int lc = propertiesValue % 9;
		int remainder = propertiesValue / 9;
		int lp = remainder % 5;
		int pb = remainder / 5;
		if (lc > 8 || lp > 4 || pb > 4)
		{
			return false;
		}

		byte[] properties = new byte[5];
		Buffer.BlockCopy(content, 12, properties, 0, properties.Length);
		int bodyLength = checked((int)declaredLength - 8);
		try
		{
			using (MemoryStream input = new MemoryStream(content, 17, (int)compressedLength, false))
			using (LzmaStream lzma = LzmaStream.Create(
				properties, input, compressedLength, bodyLength, false))
			using (MemoryStream body = new MemoryStream(bodyLength))
			{
				byte[] buffer = new byte[81920];
				while (body.Length <= bodyLength)
				{
					int read = lzma.Read(buffer, 0, Math.Min(buffer.Length, bodyLength + 1 - (int)body.Length));
					if (read <= 0)
					{
						break;
					}
					body.Write(buffer, 0, read);
				}
				if (body.Length != bodyLength || lzma.ReadByte() != -1)
				{
					return false;
				}
				fws = new byte[bodyLength + 8];
				fws[0] = (byte)'F';
				fws[1] = (byte)'W';
				fws[2] = (byte)'S';
				fws[3] = content[3];
				WriteUInt32(fws, 4, declaredLength);
				Buffer.BlockCopy(body.GetBuffer(), 0, fws, 8, bodyLength);
				return IsValidFws(fws);
			}
		}
		catch (Exception ex) when (ex is IOException || ex is InvalidDataException ||
			ex is ArgumentException || ex.GetType().Assembly == typeof(LzmaStream).Assembly)
		{
			return false;
		}
	}

	private static bool TryPatchClassNameTag(
		byte[] body,
		string sourceClass,
		string targetClass,
		ref int sourceMatches,
		ref int targetMatches,
		out byte[] patchedBody)
	{
		patchedBody = null;
		if (body == null || body.Length < 2)
		{
			return false;
		}
		int cursor = 0;
		ushort count = ReadUInt16(body, cursor);
		cursor += 2;
		using (MemoryStream output = new MemoryStream())
		{
			WriteUInt16(output, count);
			for (int index = 0; index < count; index++)
			{
				if (cursor + 2 > body.Length)
				{
					return false;
				}
				ushort tagId = ReadUInt16(body, cursor);
				cursor += 2;
				if (!TryReadNullTerminated(body, ref cursor, out string name))
				{
					return false;
				}
				string replacement = name == sourceClass ? targetClass : name;
				if (name == sourceClass)
				{
					sourceMatches++;
				}
				else if (name == targetClass)
				{
					targetMatches++;
				}
				WriteUInt16(output, tagId);
				WriteNullTerminated(output, replacement);
			}
			if (cursor != body.Length)
			{
				return false;
			}
			patchedBody = output.ToArray();
			return true;
		}
	}

	private static bool TryPatchDoAbc(
		byte[] body,
		string sourceToken,
		string targetToken,
		string sourceClass,
		string targetClass,
		ref int sourceMatches,
		ref int targetMatches,
		out byte[] patchedBody)
	{
		patchedBody = null;
		if (body == null || body.Length < 8)
		{
			return false;
		}
		int abcOffset = 4;
		int nameEnd = Array.IndexOf(body, (byte)0, abcOffset);
		if (nameEnd < 0 || nameEnd + 1 >= body.Length)
		{
			return false;
		}
		abcOffset = nameEnd + 1;
		if (abcOffset + 4 > body.Length)
		{
			return false;
		}
		int cursor = abcOffset + 4;
		if (!SkipU30Table(body, ref cursor))
		{
			return false;
		}
		if (!SkipU30Table(body, ref cursor))
		{
			return false;
		}
		if (!SkipDoubleTable(body, ref cursor))
		{
			return false;
		}
		if (cursor >= body.Length)
		{
			return false;
		}
		int stringCountOffset = cursor;
		if (!TryReadU30(body, ref cursor, out uint stringCount) || stringCount > 0x3fffffff)
		{
			return false;
		}
		using (MemoryStream output = new MemoryStream())
		{
			output.Write(body, 0, stringCountOffset);
			WriteU30(output, stringCount);
			for (uint index = 1; index < stringCount; index++)
			{
				if (!TryReadU30(body, ref cursor, out uint length) || length > int.MaxValue ||
					cursor + (long)length > body.Length)
				{
					return false;
				}
				string value = Encoding.UTF8.GetString(body, cursor, (int)length);
				string replacement = value == sourceToken ? targetToken :
					value == sourceClass ? targetClass : value;
				if (value == sourceToken || value == sourceClass)
				{
					sourceMatches++;
				}
				else if (value == targetToken || value == targetClass)
				{
					targetMatches++;
				}
				byte[] encoded = Encoding.UTF8.GetBytes(replacement);
				WriteU30(output, (uint)encoded.Length);
				output.Write(encoded, 0, encoded.Length);
				cursor += (int)length;
			}
			output.Write(body, cursor, body.Length - cursor);
			patchedBody = output.ToArray();
			return true;
		}
	}

	private static bool SkipU30Table(byte[] content, ref int cursor)
	{
		if (!TryReadU30(content, ref cursor, out uint count) || count > 0x3fffffff)
		{
			return false;
		}
		for (uint index = 1; index < count; index++)
		{
			if (!TryReadU30(content, ref cursor, out _))
			{
				return false;
			}
		}
		return true;
	}

	private static bool SkipDoubleTable(byte[] content, ref int cursor)
	{
		if (!TryReadU30(content, ref cursor, out uint count) || count > 0x3fffffff ||
			count > (uint)((content.Length - cursor) / 8 + 1))
		{
			return false;
		}
		long valueCount = count == 0 ? 0 : (long)count - 1;
		long end = cursor + valueCount * 8;
		if (end > content.Length)
		{
			return false;
		}
		cursor = (int)end;
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

	private static bool TryParseTags(byte[] content, int offset, out List<SwfTag> tags)
	{
		tags = new List<SwfTag>();
		while (offset < content.Length)
		{
			if (offset + 2 > content.Length)
			{
				return false;
			}
			ushort header = ReadUInt16(content, offset);
			offset += 2;
			int code = header >> 6;
			long length = header & 0x3f;
			if (length == 0x3f)
			{
				if (offset + 4 > content.Length)
				{
					return false;
				}
				length = ReadUInt32(content, offset);
				offset += 4;
			}
			if (length < 0 || length > int.MaxValue || offset + length > content.Length)
			{
				return false;
			}
			byte[] body = new byte[(int)length];
			Buffer.BlockCopy(content, offset, body, 0, body.Length);
			offset += body.Length;
			tags.Add(new SwfTag(code, body));
			if (code == 0)
			{
				return offset == content.Length;
			}
		}
		return false;
	}

	private static bool TryReadNullTerminated(byte[] content, ref int cursor, out string value)
	{
		value = null;
		int start = cursor;
		while (cursor < content.Length && content[cursor] != 0)
		{
			cursor++;
		}
		if (cursor >= content.Length)
		{
			return false;
		}
		value = Encoding.UTF8.GetString(content, start, cursor - start);
		cursor++;
		return true;
	}

	private static bool IsValidFws(byte[] content)
	{
		return content != null && content.Length >= 8 && content.Length <= MaximumSwfBytes &&
			content[0] == 'F' && content[1] == 'W' && content[2] == 'S' &&
			ReadUInt32(content, 4) == content.Length;
	}

	private static void WriteTag(Stream output, SwfTag tag)
	{
		int length = tag.Body.Length;
		WriteUInt16(output, (ushort)(tag.Code << 6 | (length < 0x3f ? length : 0x3f)));
		if (length >= 0x3f)
		{
			WriteUInt32(output, (uint)length);
		}
		output.Write(tag.Body, 0, length);
	}

	private static bool TryReadU30(byte[] content, ref int cursor, out uint value)
	{
		value = 0;
		for (int index = 0; index < 5; index++)
		{
			if (cursor >= content.Length)
			{
				return false;
			}
			byte current = content[cursor++];
			value |= (uint)(current & 0x7f) << (index * 7);
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

	private static void WriteNullTerminated(Stream output, string value)
	{
		byte[] bytes = Encoding.UTF8.GetBytes(value);
		output.Write(bytes, 0, bytes.Length);
		output.WriteByte(0);
	}

	private static ushort ReadUInt16(byte[] content, int offset)
	{
		return (ushort)(content[offset] | content[offset + 1] << 8);
	}

	private static uint ReadUInt32(byte[] content, int offset)
	{
		return (uint)(content[offset] | content[offset + 1] << 8 |
			content[offset + 2] << 16 | content[offset + 3] << 24);
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

	private static void WriteUInt32(byte[] content, int offset, uint value)
	{
		content[offset] = (byte)value;
		content[offset + 1] = (byte)(value >> 8);
		content[offset + 2] = (byte)(value >> 16);
		content[offset + 3] = (byte)(value >> 24);
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
