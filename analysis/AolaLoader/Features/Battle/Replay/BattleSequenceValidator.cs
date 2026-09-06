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
	private static readonly FieldRule[] PreludeSchema = Fields("eventId:i");
	private static readonly FieldRule[] PreFightSchema = Fields("ul:s", "msg:s");

	public static BattleSequencePlan Validate(IReadOnlyList<AolaSendRequest> requests)
	{
		if (requests == null || requests.Count == 0)
		{
			throw new InvalidOperationException("战斗状态发送至少需要一条消息。");
		}
		List<BattleSequenceItem> setupItems = new List<BattleSequenceItem>();
		List<BattleTurnGroup> turnGroups = new List<BattleTurnGroup>();
		List<BattleSequenceItem> currentTurnItems = null;
		int currentTurn = -1;
		bool preludeSeen = false;
		bool entrySeen = false;
		bool actionSeen = false;
		bool battlePhaseStarted = false;
		for (int index = 0; index < requests.Count; index++)
		{
			AolaSendRequest request = requests[index] ?? throw new InvalidOperationException(
				string.Format("第 {0} 条消息为空。", index + 1));
			JObject parameters = JObject.Parse(request.ParametersJson ?? "{}");
			if (request.ExtensionId == 13 && (request.Command == "1408" || request.Command == "1409"))
			{
				throw Invalid(index, "状态模式不接受 1408/1409 自动战斗开关");
			}
			if (request.ExtensionId == 42 && request.Command == "74_1")
			{
				if (preludeSeen || battlePhaseStarted)
				{
					throw Invalid(index, "74_1 活动入口最多出现一次，并且必须位于 54_22 之前");
				}
				ValidateObject(index, parameters, PreludeSchema);
				if (parameters.Value<int>("eventId") <= 0)
				{
					throw Invalid(index, "eventId 必须为正整数");
				}
				preludeSeen = true;
				setupItems.Add(new BattleSequenceItem(request, BattleSequenceItemKind.Prelude));
				continue;
			}
			if (request.ExtensionId == 15 && request.Command == "54_22")
			{
				if (entrySeen || battlePhaseStarted)
				{
					throw Invalid(index, "一份状态序列只允许一个战斗入口，并且入口必须位于所有回合操作之前");
				}
				ValidateObject(index, parameters, EntrySchema);
				entrySeen = true;
				battlePhaseStarted = true;
				setupItems.Add(new BattleSequenceItem(request, BattleSequenceItemKind.Entry));
				continue;
			}
			if (request.ExtensionId == 16 && request.Command == "preFightLoad")
			{
				if (!entrySeen || actionSeen)
				{
					throw Invalid(index, "preFightLoad 只能紧随战斗入口，由 Flash 自行发送");
				}
				ValidateObject(index, parameters, PreFightSchema);
				setupItems.Add(new BattleSequenceItem(request, BattleSequenceItemKind.FlashOwned));
				continue;
			}
			if (request.ExtensionId == 13 && ActionSchemas.TryGetValue(request.Command, out FieldRule[] schema))
			{
				ValidateObject(index, parameters, schema);
				int turn = parameters.Value<int>("turn");
				if (turn < 0)
				{
					throw Invalid(index, "turn 不能为负数");
				}
				battlePhaseStarted = true;
				actionSeen = true;
				if (currentTurnItems == null || turn != currentTurn)
				{
					if (currentTurnItems != null)
					{
						if ((long)turn != (long)currentTurn + 1L)
						{
							throw Invalid(index, string.Format(
								"回合组必须严格连续递增；上一组 turn={0}，当前 turn={1}", currentTurn, turn));
						}
						turnGroups.Add(new BattleTurnGroup(currentTurn, currentTurnItems));
					}
					currentTurn = turn;
					currentTurnItems = new List<BattleSequenceItem>();
				}
				currentTurnItems.Add(new BattleSequenceItem(request, BattleSequenceItemKind.TurnAction));
				continue;
			}
			if (!battlePhaseStarted)
			{
				setupItems.Add(new BattleSequenceItem(request, BattleSequenceItemKind.PrefixPassThrough));
				continue;
			}
			throw Invalid(index, "战斗阶段开始后只接受 preFightLoad 和已验证的 id=13 回合操作");
		}
		if (currentTurnItems != null)
		{
			turnGroups.Add(new BattleTurnGroup(currentTurn, currentTurnItems));
		}
		if (preludeSeen && !entrySeen)
		{
			throw new InvalidOperationException("id=42/cmd=74_1 活动入口必须与 id=15/cmd=54_22 一起使用。");
		}
		if (!entrySeen && !actionSeen)
		{
			throw new InvalidOperationException("战斗状态发送至少需要一条已验证的 id=13 回合操作。");
		}
		return new BattleSequencePlan(setupItems, turnGroups, entrySeen);
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
	PrefixPassThrough,
	Prelude,
	Entry,
	FlashOwned,
	TurnAction
}

internal sealed class BattleSequenceItem
{
	public BattleSequenceItem(AolaSendRequest request, BattleSequenceItemKind kind)
	{
		Request = request;
		Kind = kind;
	}
	public AolaSendRequest Request { get; }
	public BattleSequenceItemKind Kind { get; }
}

internal sealed class BattleTurnGroup
{
	public BattleTurnGroup(int turn, IReadOnlyList<BattleSequenceItem> items)
	{
		Turn = turn;
		Items = items ?? throw new ArgumentNullException(nameof(items));
	}

	public int Turn { get; }
	public IReadOnlyList<BattleSequenceItem> Items { get; }
}

internal sealed class BattleSequencePlan
{
	public BattleSequencePlan(
		IReadOnlyList<BattleSequenceItem> setupItems,
		IReadOnlyList<BattleTurnGroup> turnGroups,
		bool startsNewBattle)
	{
		SetupItems = setupItems;
		TurnGroups = turnGroups;
		StartsNewBattle = startsNewBattle;
	}

	public IReadOnlyList<BattleSequenceItem> SetupItems { get; }
	public IReadOnlyList<BattleTurnGroup> TurnGroups { get; }
	public bool StartsNewBattle { get; }
}
