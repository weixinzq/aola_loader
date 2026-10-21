// 架构角色：组合 SWF 格式适配和位图变换，对资源管线暴露统一 IResourceResponseTransformer。
// 数据流：ResourceTransformInput -> decode/transform/validate -> ResourceTransformResult。
using System;
using System.Text;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;

namespace AolaLoader.ResourceInterception.Transformers;

internal sealed class AolaSwfResourceTransformer : IResourceResponseTransformer
{
	private readonly byte[] _sourceToken;
	private readonly byte[] _targetToken;
	private readonly int _expectedCount;
	private readonly double _scaleFactor;
	private readonly bool _structuralClassAdaptation;
	private readonly bool _makeBitmapsTransparent;

	public AolaSwfResourceTransformer(
		string sourceToken,
		string targetToken,
		int expectedCount,
		double scaleFactor,
		bool structuralClassAdaptation = false,
		bool makeBitmapsTransparent = false)
	{
		if (string.IsNullOrWhiteSpace(sourceToken) || string.IsNullOrWhiteSpace(targetToken))
		{
			throw new ArgumentException("Source and target class tokens are required.");
		}
		if (!structuralClassAdaptation && sourceToken.Length != targetToken.Length)
		{
			throw new ArgumentException("Same-length SWF adaptation requires equal token lengths.");
		}
		if (expectedCount < 0 || scaleFactor <= 0 || double.IsNaN(scaleFactor) || double.IsInfinity(scaleFactor))
		{
			throw new ArgumentOutOfRangeException(nameof(expectedCount));
		}
		_sourceToken = Encoding.ASCII.GetBytes(sourceToken);
		_targetToken = Encoding.ASCII.GetBytes(targetToken);
		_expectedCount = expectedCount;
		_scaleFactor = scaleFactor;
		_structuralClassAdaptation = structuralClassAdaptation;
		_makeBitmapsTransparent = makeBitmapsTransparent;
	}

	public string Name => "aola.swf.class-adaptation";

	public string InputContract => "Complete bounded FWS response";

	public ResourceTransformResult Transform(ResourceTransformInput input)
	{
		if (input == null)
		{
			throw new ArgumentNullException(nameof(input));
		}
		byte[] remote = input.ContentUnsafe;
		byte[] output = null;
		if (_structuralClassAdaptation)
		{
			if (!AolaSwfClassAdapter.TryAdapt(
				remote,
				Encoding.ASCII.GetString(_sourceToken),
				Encoding.ASCII.GetString(_targetToken),
				out output))
			{
				return ResourceTransformResult.Reject(
					"swf.structural_adaptation_failed",
					"SWF structural class adaptation rejected the candidate.");
			}
		}
		else
		{
			if (!AolaSwfClassAdapter.TryDecodeToFws(remote, out byte[] fws))
			{
				return ResourceTransformResult.Reject(
					"swf.decode_failed",
					"SWF response could not be decoded to a complete bounded FWS document.");
			}
			bool requiresScale = Math.Abs(_scaleFactor - 1) >= 0.0001 &&
				CountOccurrences(fws, _sourceToken) > 0;
			if (!TryAdaptFws(fws, _sourceToken, _targetToken, _expectedCount, out byte[] adapted))
			{
				return ResourceTransformResult.Reject(
					"swf.class_contract_failed",
					"SWF class token count or FWS contract did not match.");
			}
			if (requiresScale && !AolaSwfBitmapScaler.TryScaleFws(
				adapted,
				_scaleFactor,
				out output))
			{
				return ResourceTransformResult.Reject(
					"swf.scale_failed",
					"SWF bitmap scale compensation failed.");
			}
			if (!requiresScale)
			{
				output = adapted;
			}
		}

		if (_makeBitmapsTransparent &&
			!AolaSwfBitmapScaler.TryMakeTransparentFws(output, out output))
		{
			return ResourceTransformResult.Reject(
				"swf.transparency_failed",
				"SWF bitmap transparency conversion failed.");
		}
		return ResourceTransformResult.SuccessOwned(output, "application/x-shockwave-flash");
	}

	internal static bool TryAdaptFws(
		byte[] content,
		byte[] sourceToken,
		byte[] targetToken,
		int expectedCount,
		out byte[] adapted)
	{
		adapted = null;
		if (!SwfResponseHeaderValidator.IsValidCompleteFws(content) || sourceToken == null || targetToken == null ||
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
