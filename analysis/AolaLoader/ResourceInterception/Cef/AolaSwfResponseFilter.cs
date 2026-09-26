// 架构角色：CEF IResponseFilter 适配器，在流式回调中有界收集响应并执行纯 transformer。
// 数据流：远端响应 chunks -> BoundedResourceResponseProcessor -> 变换后响应 chunks。
using System;
using System.IO;
using System.Text;
using CefSharp;
using AolaLoader.ResourceInterception.Pipeline;
using AolaLoader.ResourceInterception.Transformers;

namespace AolaLoader.ResourceInterception.Cef;

internal sealed class AolaSwfResponseFilter : IResponseFilter
{
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private readonly byte[] _sourceToken;
	private readonly byte[] _targetToken;
	private readonly int _expectedCount;
	private readonly double _scaleFactor;
	private readonly bool _structuralClassAdaptation;
	private readonly bool _makeBitmapsTransparent;
	private MemoryStream _input = new MemoryStream();
	private byte[] _output;
	private int _outputOffset;

	public AolaSwfResponseFilter(
		string sourceToken,
		string targetToken,
		int expectedCount,
		double scaleFactor,
		bool structuralClassAdaptation = false,
		bool makeBitmapsTransparent = false)
	{
		_sourceToken = Encoding.ASCII.GetBytes(sourceToken ?? string.Empty);
		_targetToken = Encoding.ASCII.GetBytes(targetToken ?? string.Empty);
		_expectedCount = expectedCount;
		_scaleFactor = scaleFactor;
		_structuralClassAdaptation = structuralClassAdaptation;
		_makeBitmapsTransparent = makeBitmapsTransparent;
	}

	public bool InitFilter()
	{
		return _sourceToken.Length > 0 && _targetToken.Length > 0 &&
			(_structuralClassAdaptation || _sourceToken.Length == _targetToken.Length);
	}

	public FilterStatus Filter(
		Stream dataIn,
		out long dataInRead,
		Stream dataOut,
		out long dataOutWritten)
	{
		dataInRead = 0;
		dataOutWritten = 0;
		if (_output != null)
		{
			return WriteOutput(dataOut, out dataOutWritten);
		}

		if (dataIn != null)
		{
			long available = dataIn.Length - dataIn.Position;
			if (available < 0 || _input.Length + available > MaximumSwfBytes)
			{
				return FilterStatus.Error;
			}
			byte[] buffer = new byte[Math.Min(81920, Math.Max(1, (int)Math.Min(available, int.MaxValue)))];
			while (available > 0)
			{
				int requested = (int)Math.Min(buffer.Length, available);
				int read = dataIn.Read(buffer, 0, requested);
				if (read <= 0)
				{
					break;
				}
				_input.Write(buffer, 0, read);
				dataInRead += read;
				available -= read;
			}
			return FilterStatus.NeedMoreData;
		}

		byte[] remote = _input.ToArray();
		if (_structuralClassAdaptation)
		{
			string sourceToken = Encoding.ASCII.GetString(_sourceToken);
			string targetToken = Encoding.ASCII.GetString(_targetToken);
			if (!AolaSwfClassAdapter.TryAdapt(remote, sourceToken, targetToken, out _output))
			{
				return FilterStatus.Error;
			}
		}
		else
		{
			bool requiresScaleCompensation = Math.Abs(_scaleFactor - 1) >= 0.0001 &&
				CountOccurrences(remote, _sourceToken) > 0;
			if (!TryAdaptFws(remote, _sourceToken, _targetToken, _expectedCount, out byte[] adapted))
			{
				return FilterStatus.Error;
			}
			if (requiresScaleCompensation)
			{
				if (!AolaSwfBitmapScaler.TryScaleFws(adapted, _scaleFactor, out _output))
				{
					return FilterStatus.Error;
				}
			}
			else
			{
				_output = adapted;
			}
		}
		if (_makeBitmapsTransparent &&
			!AolaSwfBitmapScaler.TryMakeTransparentFws(_output, out _output))
		{
			return FilterStatus.Error;
		}
		return WriteOutput(dataOut, out dataOutWritten);
	}

	public void Dispose()
	{
		_input?.Dispose();
		_input = null;
		_output = null;
	}

	internal static bool TryAdaptFws(
		byte[] content,
		byte[] sourceToken,
		byte[] targetToken,
		int expectedCount,
		out byte[] adapted)
	{
		adapted = null;
		if (!IsValidFws(content) || sourceToken == null || targetToken == null ||
			sourceToken.Length == 0 || sourceToken.Length != targetToken.Length)
		{
			return false;
		}

		byte[] result = (byte[])content.Clone();
		int replacements = ReplaceSameLength(result, sourceToken, targetToken);
		if (replacements == 0 && CountOccurrences(result, targetToken) > 0)
		{
			replacements = CountOccurrences(result, targetToken);
		}
		if (replacements == 0 || expectedCount > 0 && replacements != expectedCount)
		{
			return false;
		}
		adapted = result;
		return true;
	}

	internal static bool IsValidFws(byte[] content)
	{
		return SwfResponseHeaderValidator.IsValidCompleteFws(content, MaximumSwfBytes);
	}

	private FilterStatus WriteOutput(Stream dataOut, out long dataOutWritten)
	{
		dataOutWritten = 0;
		if (dataOut == null || _output == null)
		{
			return FilterStatus.Error;
		}
		long capacity = dataOut.Length - dataOut.Position;
		if (capacity <= 0)
		{
			return FilterStatus.NeedMoreData;
		}
		int remaining = _output.Length - _outputOffset;
		int count = (int)Math.Min(capacity, remaining);
		dataOut.Write(_output, _outputOffset, count);
		_outputOffset += count;
		dataOutWritten = count;
		return _outputOffset < _output.Length ? FilterStatus.NeedMoreData : FilterStatus.Done;
	}

	private static int ReplaceSameLength(byte[] content, byte[] search, byte[] replacement)
	{
		int count = 0;
		for (int offset = 0; offset <= content.Length - search.Length; offset++)
		{
			bool match = true;
			for (int index = 0; index < search.Length; index++)
			{
				if (content[offset + index] != search[index])
				{
					match = false;
					break;
				}
			}
			if (!match)
			{
				continue;
			}
			Buffer.BlockCopy(replacement, 0, content, offset, replacement.Length);
			count++;
			offset += search.Length - 1;
		}
		return count;
	}

	private static int CountOccurrences(byte[] content, byte[] search)
	{
		int count = 0;
		for (int offset = 0; offset <= content.Length - search.Length; offset++)
		{
			bool match = true;
			for (int index = 0; index < search.Length; index++)
			{
				if (content[offset + index] != search[index])
				{
					match = false;
					break;
				}
			}
			if (match)
			{
				count++;
				offset += search.Length - 1;
			}
		}
		return count;
	}
}
