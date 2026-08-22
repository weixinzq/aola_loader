using System;

namespace AolaLoader.ResourceInterception.Pipeline;

internal static class SwfResponseHeaderValidator
{
	public static bool IsValidCompleteFws(byte[] content, long maximumBytes = 16 * 1024 * 1024)
	{
		return content != null && content.Length >= 8 && content.LongLength <= maximumBytes &&
			content[0] == 'F' && content[1] == 'W' && content[2] == 'S' &&
			BitConverter.ToUInt32(content, 4) == content.Length;
	}

	public static bool IsSupported(byte[] header, int count, long responseLength, long maximumBytes)
	{
		if (header == null || count < 8 || count > header.Length || responseLength < 8 ||
			maximumBytes < 8 || responseLength > maximumBytes)
		{
			return false;
		}
		uint declaredLength = BitConverter.ToUInt32(header, 4);
		if (declaredLength < 8 || declaredLength > maximumBytes)
		{
			return false;
		}
		bool isFws = header[0] == 'F' && header[1] == 'W' && header[2] == 'S';
		bool isCws = header[0] == 'C' && header[1] == 'W' && header[2] == 'S';
		bool isZws = count >= 17 && header[0] == 'Z' && header[1] == 'W' && header[2] == 'S';
		if (isFws)
		{
			return responseLength == declaredLength;
		}
		if (isCws)
		{
			return true;
		}
		if (!isZws)
		{
			return false;
		}
		uint compressedLength = BitConverter.ToUInt32(header, 8);
		uint dictionarySize = BitConverter.ToUInt32(header, 13);
		return responseLength >= 17 && compressedLength == responseLength - 17 &&
			dictionarySize > 0 && dictionarySize <= 64 * 1024 * 1024;
	}
}
