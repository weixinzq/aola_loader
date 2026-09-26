// 架构角色：阵容功能门面，负责读取、保存方案并创建一次性恢复会话。
// 数据流：UI 请求 -> packet source/command sender/battle gate -> LineupSession 或方案结果。
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.ActiveSend;
using AolaLoader.Features.Battle.State;
using AolaLoader.PacketHost;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Lineup;

internal sealed class LineupCoordinator
{
	private readonly IAolaPacketEventSource _packets;
	private readonly IAolaCommandSender _sender;
	private readonly IBattleStateSource _battle;
	private int _running;

	public LineupCoordinator(IAolaPacketEventSource packets, IAolaCommandSender sender, IBattleStateSource battle)
	{
		_packets = packets;
		_sender = sender;
		_battle = battle;
	}

	private void Enter()
	{
		if (Interlocked.CompareExchange(ref _running, 1, 0) != 0) throw new InvalidOperationException("阵容任务正在执行。");
	}
	private void CheckIdle()
	{
		AolaBattleSnapshot state = _battle.CurrentSnapshot;
		if (state.HasBattle && !state.IsEnded) throw new InvalidOperationException("请结束战斗后再操作阵容。");
	}

	public async Task<LineupPreset> ReadAsync(Action<string> report, CancellationToken token)
	{
		Enter();
		try
		{
			CheckIdle();
			using (var session = new LineupSession(_packets, _sender))
			{
				report("正在读取背包及配置…");
				LineupPreset first = await ReadBackpack(session, token).ConfigureAwait(false);
				LineupPreset last = await ReadBackpack(session, token).ConfigureAwait(false);
				if (!JToken.DeepEquals(JToken.FromObject(first.Pets), JToken.FromObject(last.Pets)))
					throw new InvalidOperationException("读取期间背包发生变化，请重新读取。");
				session.Check();
				report("已读取 " + last.Pets.Count + " 只亚比，可保存为 JSON。");
				return last;
			}
		}
		finally { Interlocked.Exchange(ref _running, 0); }
	}

	public async Task RestoreAsync(LineupPreset preset, Action<string> report, CancellationToken token)
	{
		LineupPresetStore.Validate(preset);
		Enter();
		try
		{
			CheckIdle();
			using (var session = new LineupSession(_packets, _sender))
			{
				report("正在核对账号、目标亚比及配置…");
				LineupPreset current = await ReadBackpack(session, token).ConfigureAwait(false);
				if (current.OwnerPlayerId != preset.OwnerPlayerId) throw new InvalidOperationException("方案所属账号与当前账号不同。");
				var bound = new Dictionary<int, HashSet<int>>();
				foreach (LineupPet target in preset.Pets)
				{
					LineupPet actual = await ReadPet(session, target.PetId, preset.OwnerPlayerId, token).ConfigureAwait(false);
					CheckApplicable(target, actual);
					if (target.CrystalKeys != null && !Same(target.CrystalKeys, actual.CrystalKeys))
					{
						for (int slot = 0; slot < 2; slot++)
							if (target.CrystalKeys[slot] == 0 && actual.CrystalKeys[slot] != 0)
								throw new InvalidOperationException(target.Name + " 需要清空晶钥槽，当前版本尚未确认卸下接口，未开始修改。");
						JObject response = await session.RequestAsync(42, "ACK241227_1", new JObject { ["petId"] = target.PetId }, "ACK241227_1", token).ConfigureAwait(false);
						RequireSuccess(response, "查询已绑定晶钥");
						if (!(response["ids"] is JArray ids) || ids.Any(id => id.Type != JTokenType.Integer)) throw new InvalidDataException("无法识别晶钥绑定资料。");
						bound[target.PetId] = new HashSet<int>(ids.Values<int>());
						if (target.CrystalKeys.Any(id => id > 0 && !bound[target.PetId].Contains(id))) throw new InvalidOperationException(target.Name + " 的目标晶钥尚未绑定，未开始修改。");
					}
				}
				LineupArtifact[] desiredArtifacts = preset.Pets.Where(p => p.SoulArtifacts != null).SelectMany(p => p.SoulArtifacts).Where(a => a != null).ToArray();
				if (desiredArtifacts.Length > 0)
				{
					JObject inventory = await session.RequestAsync(42, "ATT231229_0", new JObject(), "ATT231229_0", token).ConfigureAwait(false);
					if (inventory["r"] != null) RequireSuccess(inventory, "读取魂器");
					JObject[] owned = inventory.Descendants().OfType<JObject>().Where(item => item["ui"]?.Type == JTokenType.Integer && item["ti"]?.Type == JTokenType.Integer).ToArray();
					foreach (LineupArtifact artifact in desiredArtifacts)
						if (!owned.Any(item => item.Value<int>("ui") == artifact.InstanceId && item.Value<int>("ti") == artifact.ConfigId))
							throw new InvalidOperationException("未能从魂器资料确认实例 " + artifact.InstanceId + "，未开始修改。");
				}
				CheckIdle();
				string desiredOrder = string.Join("#", preset.Pets.Select(p => p.PetId));
				if (desiredOrder != string.Join("#", current.Pets.Select(p => p.PetId)))
				{
					report("正在恢复背包亚比及顺序…");
					JObject changed = await session.RequestAsync(13, "1222", new JObject { ["pms"] = desiredOrder }, "2222", token).ConfigureAwait(false);
					if (changed.Value<string>("pms") != desiredOrder) throw new InvalidOperationException("服务器返回的背包名单与方案不符。");
					current = await ReadBackpack(session, token).ConfigureAwait(false);
					if (string.Join("#", current.Pets.Select(p => p.PetId)) != desiredOrder) throw new InvalidOperationException("背包回读不一致，已停止。");
					report("背包阵容已核对一致。");
				}
				foreach (LineupPet target in preset.Pets)
				{
					CheckIdle();
					LineupPet actual = await ReadPet(session, target.PetId, preset.OwnerPlayerId, token).ConfigureAwait(false);
					CheckApplicable(target, actual);
					if (target.SoulCards != null && !Same(target.SoulCards, actual.SoulCards))
					{
						report(target.Name + "：正在查找魂卡…");
						var args = new JObject { ["petId"] = target.PetId, ["ids"] = new JArray(target.SoulCards) };
						JObject found = await session.RequestAsync(42, "ASC221104_40", args, "ASC221104_40", token).ConfigureAwait(false);
						// The lookup is not a mutation acknowledgement. Never infer ownership from _41.
						if (found["r"] != null) RequireSuccess(found, "查找魂卡");
						else if (!found.Properties().Any(p => p.Name != "_cmd")) throw new InvalidDataException("魂卡查找响应没有资料，已停止。");
						args["bk"] = 0;
						args["tf"] = true;
						report(target.Name + "：正在穿戴魂卡…");
						RequireSuccess(await session.RequestAsync(42, "ASC221104_2", args, "ASC221104_2", token).ConfigureAwait(false), "穿戴魂卡");
						actual = await ReadPet(session, target.PetId, preset.OwnerPlayerId, token).ConfigureAwait(false);
						if (!Same(target.SoulCards, actual.SoulCards)) throw new InvalidOperationException(target.Name + " 魂卡回读不一致。");
						report(target.Name + "：魂卡已核对。");
					}
					if (target.SoulArtifacts != null)
					{
						for (int slot = 0; slot < target.SoulArtifacts.Length; slot++)
						{
							LineupArtifact artifact = target.SoulArtifacts[slot];
							if (artifact == null || ArtifactMatches(artifact, actual.SoulArtifacts?[slot])) continue;
							report(target.Name + "：正在穿戴魂器 " + artifact.InstanceId + "…");
							RequireSuccess(await session.RequestAsync(42, "ATT231229_1", new JObject { ["petId"] = target.PetId, ["ui"] = artifact.InstanceId }, "ATT231229_1", token).ConfigureAwait(false), "穿戴魂器");
							actual = await ReadPet(session, target.PetId, preset.OwnerPlayerId, token).ConfigureAwait(false);
							if (!ArtifactMatches(artifact, actual.SoulArtifacts?[slot])) throw new InvalidOperationException(target.Name + " 魂器回读不一致。");
							report(target.Name + "：魂器槽 " + (slot + 1) + " 已核对。");
						}
					}
					if (target.CrystalKeys != null)
					{
						for (int slot = 0; slot < 2; slot++)
						{
							if (target.CrystalKeys[slot] == actual.CrystalKeys[slot]) continue;
							report(target.Name + "：正在切换晶钥槽 " + (slot + 1) + "…");
							RequireSuccess(await session.RequestAsync(42, "ACK241227_3", new JObject { ["petId"] = target.PetId, ["slotId"] = slot, ["id"] = target.CrystalKeys[slot] }, "ACK241227_3", token).ConfigureAwait(false), "切换晶钥");
							actual = await ReadPet(session, target.PetId, preset.OwnerPlayerId, token).ConfigureAwait(false);
							if (actual.CrystalKeys?[slot] != target.CrystalKeys[slot]) throw new InvalidOperationException(target.Name + " 晶钥回读不一致。");
							report(target.Name + "：晶钥槽 " + (slot + 1) + " 已核对。");
						}
					}
					report(target.Name + "：本只处理完成。");
				}
				report("正在重新读取并核对整套阵容…");
				LineupPreset final = await ReadBackpack(session, token).ConfigureAwait(false);
				if (string.Join("#", final.Pets.Select(p => p.PetId)) != desiredOrder) throw new InvalidOperationException("最终阵容顺序与方案不符。");
				foreach (LineupPet target in preset.Pets)
				{
					LineupPet actual = final.Pets.Single(p => p.PetId == target.PetId);
					CheckApplicable(target, actual);
					if (target.SoulCards != null && !Same(target.SoulCards, actual.SoulCards)) throw new InvalidOperationException(target.Name + " 的魂卡在最终核对时不一致。");
					if (target.CrystalKeys != null && !Same(target.CrystalKeys, actual.CrystalKeys)) throw new InvalidOperationException(target.Name + " 的晶钥在最终核对时不一致。");
					if (target.SoulArtifacts != null)
						for (int slot = 0; slot < 2; slot++)
							if (target.SoulArtifacts[slot] != null && !ArtifactMatches(target.SoulArtifacts[slot], actual.SoulArtifacts?[slot]))
								throw new InvalidOperationException(target.Name + " 的魂器在最终核对时不一致。");
				}
				token.ThrowIfCancellationRequested();
				session.Check();
				report("恢复成功：阵容顺序和参与恢复的配置均已通过服务器回读核对。");
			}
		}
		finally { Interlocked.Exchange(ref _running, 0); }
	}

	private static bool Same(int[] expected, int[] actual) => actual != null && expected.SequenceEqual(actual);
	private static bool ArtifactMatches(LineupArtifact expected, LineupArtifact actual) =>
		actual != null && expected.InstanceId == actual.InstanceId && expected.ConfigId == actual.ConfigId;

	private static void CheckApplicable(LineupPet target, LineupPet actual)
	{
		if (target.PetId != actual.PetId || target.RaceId != actual.RaceId) throw new InvalidOperationException("亚比 " + target.PetId + " 的身份与方案不符。");
		if ((target.SoulCards != null && actual.SoulCards == null) || (target.SoulArtifacts != null && actual.SoulArtifacts == null) || (target.CrystalKeys != null && actual.CrystalKeys == null))
			throw new InvalidOperationException(target.Name + " 的配置不适用或资料缺失。");
	}

	private static void RequireSuccess(JObject response, string operation)
	{
		if (response["r"]?.Type != JTokenType.Integer || response.Value<int>("r") != 1) throw new InvalidOperationException(operation + " 未获服务器明确成功响应，已停止。");
	}

	private static async Task<LineupPreset> ReadBackpack(LineupSession session, CancellationToken token)
	{
		JObject response = await session.RequestAsync(13, "1212", new JObject(), "2212", token).ConfigureAwait(false);
		if (response["pms"]?.Type != JTokenType.String || !(response["pmList"] is JArray list)) throw new InvalidDataException("背包响应不完整。");
		int[] order = response.Value<string>("pms").Split('#').Select(int.Parse).ToArray();
		var result = new LineupPreset();
		var indexed = new Dictionary<int, LineupPet>();
		foreach (JToken item in list)
		{
			if (!(item is JObject pet)) throw new InvalidDataException("背包亚比资料无效。");
			long owner = LineupPetParser.View(pet).Value<long>("m");
			session.SetOwner(owner);
			if (result.OwnerPlayerId != 0 && result.OwnerPlayerId != owner) throw new InvalidDataException("背包混入了其他账号资料。");
			result.OwnerPlayerId = owner;
			LineupPet parsed = LineupPetParser.Parse(pet);
			if (indexed.ContainsKey(parsed.PetId)) throw new InvalidDataException("背包资料包含重复亚比。");
			indexed.Add(parsed.PetId, parsed);
		}
		if (order.Length != indexed.Count || order.Any(id => !indexed.ContainsKey(id))) throw new InvalidDataException("背包名单与资料不完整或不一致。");
		result.Pets = order.Select(id => indexed[id]).ToList();
		LineupPresetStore.Validate(result);
		return result;
	}

	private static async Task<LineupPet> ReadPet(LineupSession session, int id, long owner, CancellationToken token)
	{
		JObject response = await session.RequestAsync(13, "1211", new JObject { ["id"] = id }, "2211", token).ConfigureAwait(false);
		if (!(response["pm"] is JObject pet) || LineupPetParser.View(pet).Value<long>("m") != owner) throw new InvalidDataException("单只亚比资料缺失或账号不匹配。");
		LineupPet parsed = LineupPetParser.Parse(pet);
		if (parsed.PetId != id) throw new InvalidDataException("收到的亚比编号与请求不符。");
		LineupPresetStore.Validate(new LineupPreset { OwnerPlayerId = owner, Pets = new List<LineupPet> { parsed } });
		return parsed;
	}
}

