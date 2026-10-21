// 架构角色：将官方 pet movie SWF 变换为指定形态资源，负责格式适配和输出验证。
// 数据流：远端 SWF + 形态规则 -> 变换后的 FWS 或失败关闭结果。
using System;
using System.Text;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Transformers;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class BattlePetMovieResourceTransformer : IResourceResponseTransformer
{
	private readonly int _sourceId;
	private readonly int _targetId;
	private readonly int _face;
	private readonly int _part;

	public BattlePetMovieResourceTransformer(int sourceId, int targetId, int face, int part)
	{
		_sourceId = sourceId;
		_targetId = targetId;
		_face = face;
		_part = part;
	}

	public string Name => "aola.battle.petmovie.class-adaptation";
	public string InputContract => "Complete bounded bitmap battle FWS/CWS/ZWS response";

	public ResourceTransformResult Transform(ResourceTransformInput input)
	{
		if (input == null) throw new ArgumentNullException(nameof(input));
		if (!AolaSwfClassAdapter.TryDecodeToFws(input.ContentUnsafe, out byte[] fws))
		{
			return ResourceTransformResult.Reject("battle.swf_decode_failed", "战斗模型 SWF 无法完整解压。");
		}

		byte[] targetFamily = Encoding.ASCII.GetBytes("pet" + _targetId + "_");
		byte[] sourceFamily = Encoding.ASCII.GetBytes("pet" + _sourceId + "_");
		byte[] targetLower = Encoding.ASCII.GetBytes("pet" + _targetId + "_" + _face + "_");
		byte[] sourceLower = Encoding.ASCII.GetBytes("pet" + _sourceId + "_" + _face + "_");
		byte[] targetConfigFamily = Encoding.ASCII.GetBytes("Pet" + _targetId + "Config_");
		byte[] sourceConfigFamily = Encoding.ASCII.GetBytes("Pet" + _sourceId + "Config_");
		byte[] targetUpper = Encoding.ASCII.GetBytes("Pet" + _targetId + "Config_" + _face);
		byte[] sourceUpper = Encoding.ASCII.GetBytes("Pet" + _sourceId + "Config_" + _face);
		if (Count(fws, sourceFamily) != 0 || Count(fws, sourceConfigFamily) != 0 ||
			Count(fws, targetLower) == 0 || Count(fws, targetFamily) != Count(fws, targetLower))
		{
			return ResourceTransformResult.Reject("battle.class_contract_mixed", "战斗模型分片包含混合或缺失的类名标记。");
		}
		if (_part == 0 && (Count(fws, targetUpper) == 0 ||
				Count(fws, targetConfigFamily) != Count(fws, targetUpper)) ||
			_part != 0 && Count(fws, targetConfigFamily) != 0)
		{
			return ResourceTransformResult.Reject("battle.part_contract_failed", "战斗模型配置类与分片编号不匹配。");
		}

		if (!AolaSwfResourceTransformer.TryAdaptFws(fws, targetLower, sourceLower, 0, out byte[] adapted))
		{
			return ResourceTransformResult.Reject("battle.lower_class_adaptation_failed", "战斗动作类名改写失败。");
		}
		if (_part == 0 && !AolaSwfResourceTransformer.TryAdaptFws(
			adapted, targetUpper, sourceUpper, 0, out adapted))
		{
			return ResourceTransformResult.Reject("battle.config_class_adaptation_failed", "战斗配置类名改写失败。");
		}
		if (Count(adapted, targetFamily) != 0 || Count(adapted, targetConfigFamily) != 0 ||
			Count(adapted, sourceLower) == 0 || _part == 0 && Count(adapted, sourceUpper) == 0)
		{
			return ResourceTransformResult.Reject("battle.class_contract_failed", "战斗模型类契约校验失败。");
		}
		return ResourceTransformResult.SuccessOwned(adapted, "application/x-shockwave-flash");
	}

	private static int Count(byte[] content, byte[] token)
	{
		int count = 0;
		for (int offset = 0; offset <= content.Length - token.Length; offset++)
		{
			int index = 0;
			while (index < token.Length && content[offset + index] == token[index]) index++;
			if (index != token.Length) continue;
			count++;
			offset += token.Length - 1;
		}
		return count;
	}
}
