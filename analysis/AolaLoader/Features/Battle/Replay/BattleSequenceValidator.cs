using System;
using System.Collections.Generic;
using System.Linq;
using AolaSocketHack.Contracts;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.Replay;

internal static class BattleSequenceValidator
{
	private static readonly IReadOnlyDictionary<string, FieldRule[]> ActionSchemas =
		new Dictionary<string, FieldRule[]>(StringComparer.Ordinal)
		{
			["1401"] = Fields("skillId:i", "tarSId:i", "isAuto:b", "tarPSId:i", "reqPSId:i", "turn:i", "ussi:i"),
			["1402"] = Fields("itemId:i", "tarSId:i", "tarPSId:i", "reqPSId:i", "turn:i"),
			["1403"] = Fields("pmId:i", "reqPSId:i", "turn:i"),
			["1404"] = Fields("reqPSId:i", "turn:i"),
			["1405"] = Fields("tarSId:i", "tarPSId:i", "itemId:i", "reqPSId:i", "turn:i"),
			["1406"] = Fields("isAuto:b", "reqPSId:i", "turn:i"),
			["1407"] = Fields("reqPSId:i", "turn:i"),
			["1410"] = Fields("reqPSId:i", "turn:i", "ussi:i", "gmb:s")
		};
	private static readonly FieldRule[] EntrySchema = Fields(
		"si:i", "dr:i", "isHurtFight:b", "index:i", "type:i", "ddr:i",
		"t:i", "bb:i", "lv:i", "handler:s", "pb:i");
	private static readonly FieldRule[] PreFightSchema = Fields("ul:s", "msg:s");

	public static BattleSequencePlan Validate(IReadOnlyList<AolaSendRequest> requests)
	{
		if (requests == null || requests.Count == 0)
		{
			throw new InvalidOperationException("战斗状态发送至少需要一条消息。");
		}
		List<BattleSequenceItem> items = new List<BattleSequenceItem>();
		bool entrySeen = false;
		bool actionSeen = false;
		for (int index = 0; index < requests.Count; index++)
		{
			AolaSendRequest request = requests[index] ?? throw new InvalidOperationException(
				string.Format("第 {0} 条消息为空。", index + 1));
			JObject parameters = JObject.Parse(request.ParametersJson ?? "{}");
			if (request.ExtensionId == 15 && request.Command == "54_22")
			{
				if (entrySeen || actionSeen)
				{
					throw Invalid(index, "战斗入口必须只出现一次，并位于所有回合操作之前");
				}
				ValidateObject(index, parameters, EntrySchema);
				entrySeen = true;
				items.Add(new BattleSequenceItem(request, BattleSequenceItemKind.Entry, null));
				continue;
			}
			if (request.ExtensionId == 16 && request.Command == "preFightLoad")
			{
				if (!entrySeen || actionSeen)
				{
					throw Invalid(index, "preFightLoad 只能紧随战斗入口，由 Flash 自行发送");
				}
				ValidateObject(index, parameters, PreFightSchema);
				items.Add(new BattleSequenceItem(request, BattleSequenceItemKind.FlashOwned, null));
				continue;
			}
			if (request.ExtensionId == 13)
			{
				if (!entrySeen)
				{
					throw Invalid(index, "回合操作前缺少已验证的 id=15 / cmd=54_22 战斗入口");
				}
				if (!ActionSchemas.TryGetValue(request.Command, out FieldRule[] schema))
				{
					throw Invalid(index, request.Command == "1408" || request.Command == "1409"
						? "状态模式不接受 1408/1409 自动战斗开关"
						: "不是已验证的 PetClient 回合命令 1401-1407 或 1410");
				}
				ValidateObject(index, parameters, schema);
				int turn = parameters.Value<int>("turn");
				if (turn < 0)
				{
					throw Invalid(index, "turn 不能为负数");
				}
				actionSeen = true;
				items.Add(new BattleSequenceItem(request, BattleSequenceItemKind.TurnAction, turn));
				continue;
			}
			throw Invalid(index, "状态模式只接受战斗入口、preFightLoad 和已验证的 id=13 回合操作");
		}
		if (!entrySeen)
		{
			throw new InvalidOperationException("战斗状态发送缺少 id=15 / cmd=54_22 入口消息。");
		}
		return new BattleSequencePlan(items);
	}

	private static void ValidateObject(int lineIndex, JObject value, FieldRule[] schema)
	{
		string[] names = value.Properties().Select(property => property.Name).OrderBy(name => name, StringComparer.Ordinal).ToArray();
		string[] expected = schema.Select(field => field.Name).OrderBy(name => name, StringComparer.Ordinal).ToArray();
		if (!names.SequenceEqual(expected, StringComparer.Ordinal))
		{
			throw Invalid(lineIndex, "param 字段必须精确为 " + string.Join(", ", schema.Select(field => field.Name)));
		}
		foreach (FieldRule field in schema)
		{
			JToken token = value[field.Name];
			bool valid = field.Kind == FieldKind.Integer
				? token.Type == JTokenType.Integer && token.Value<long>() >= int.MinValue && token.Value<long>() <= int.MaxValue
				: field.Kind == FieldKind.Boolean
					? token.Type == JTokenType.Boolean
					: token.Type == JTokenType.String;
			if (!valid)
			{
				throw Invalid(lineIndex, field.Name + " 类型不符合已验证的 PetClient 签名");
			}
		}
	}

	private static InvalidOperationException Invalid(int index, string message) =>
		new InvalidOperationException(string.Format("第 {0} 条消息：{1}。", index + 1, message));

	private static FieldRule[] Fields(params string[] values) => values.Select(value =>
	{
		string[] parts = value.Split(':');
		return new FieldRule(parts[0], parts[1] == "i" ? FieldKind.Integer : parts[1] == "b" ? FieldKind.Boolean : FieldKind.String);
	}).ToArray();

	private enum FieldKind { Integer, Boolean, String }

	private sealed class FieldRule
	{
		public FieldRule(string name, FieldKind kind) { Name = name; Kind = kind; }
		public string Name { get; }
		public FieldKind Kind { get; }
	}
}

internal enum BattleSequenceItemKind
{
	Entry,
	FlashOwned,
	TurnAction
}

internal sealed class BattleSequenceItem
{
	public BattleSequenceItem(AolaSendRequest request, BattleSequenceItemKind kind, int? turn)
	{
		Request = request;
		Kind = kind;
		Turn = turn;
	}
	public AolaSendRequest Request { get; }
	public BattleSequenceItemKind Kind { get; }
	public int? Turn { get; }
}

internal sealed class BattleSequencePlan
{
	public BattleSequencePlan(IReadOnlyList<BattleSequenceItem> items) { Items = items; }
	public IReadOnlyList<BattleSequenceItem> Items { get; }
}
