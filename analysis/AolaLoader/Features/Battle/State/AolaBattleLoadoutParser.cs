// 架构角色：从 packet 参数中解析战斗配置分组，并保留 Missing/Empty/Known/Invalid 语义。
// 数据流：JToken/参数对象 -> BattleConfigurationState，供 snapshot 增量合并。
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Xml;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.State;

internal enum BattleConfigurationState { NotProvided, Empty, Known, Invalid }

internal sealed class BattleConfigurationItem
{
	public int Id { get; set; }
	public long InstanceId { get; set; }
	public string Details { get; set; }
	public BattleConfigurationItem Clone() => (BattleConfigurationItem)MemberwiseClone();
}

internal sealed class BattleConfigurationGroup
{
	public BattleConfigurationState State { get; set; }
	public List<BattleConfigurationItem> Items { get; } = new List<BattleConfigurationItem>();
	public BattleConfigurationGroup Clone()
	{
		var copy = new BattleConfigurationGroup { State = State };
		copy.Items.AddRange(Items.Select(item => item.Clone()));
		return copy;
	}
}

internal static class AolaBattleLoadoutParser
{
	public static readonly string[] Categories = { "equipment", "soul-card", "soul-artifact", "crystal-key" };

	public static void Parse(JObject pet, JObject view, AolaBattlePetSnapshot target)
	{
		if (pet.Property("eqp") != null)
			target.Loadout["equipment"] = ReadEquipment(pet["eqp"]);
		if (view.Property("pcp") == null) return;
		JToken token = view["pcp"];
		if (token != null && token.Type != JTokenType.String && token.Type != JTokenType.Null)
		{
			foreach (string category in Categories.Skip(1)) target.Loadout[category] = new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
			return;
		}
		string raw = (string)token;
		if (string.IsNullOrEmpty(raw))
		{
			foreach (string category in Categories.Skip(1)) target.Loadout[category] = new BattleConfigurationGroup { State = BattleConfigurationState.Empty };
			return;
		}
		try
		{
			var document = new XmlDocument { XmlResolver = null };
			using (var reader = XmlReader.Create(new StringReader(raw), new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null })) document.Load(reader);
			string[] attributes = { "soc", "tt", "ctk" };
			for (int i = 0; i < attributes.Length; i++)
			{
				if (document.DocumentElement.HasAttribute(attributes[i]))
					target.Loadout[Categories[i + 1]] = ReadAttribute(document.DocumentElement.GetAttribute(attributes[i]), i);
			}
		}
		catch (XmlException)
		{
			foreach (string category in Categories.Skip(1)) target.Loadout[category] = new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
		}
	}

	public static void PreserveMissing(AolaBattlePetSnapshot replacement, AolaBattlePetSnapshot previous)
	{
		foreach (var pair in previous.Loadout)
			if (!replacement.Loadout.ContainsKey(pair.Key)) replacement.Loadout[pair.Key] = pair.Value.Clone();
	}

	private static BattleConfigurationGroup ReadEquipment(JToken token)
	{
		var result = new BattleConfigurationGroup { State = BattleConfigurationState.Empty };
		if (token == null || token.Type == JTokenType.Null) return result;
		if (!(token is JArray array)) return new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
		foreach (JToken entry in array)
		{
			if (entry.Type == JTokenType.Null) { result.Items.Add(new BattleConfigurationItem()); continue; }
			if (!(entry is JObject obj)) { result.State = BattleConfigurationState.Invalid; return result; }
			if (obj["eq"]?.Type != JTokenType.String) return new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
			string[] parts = ((string)obj["eq"] ?? "").Split(',');
			if (parts.Length != 12 || !long.TryParse(parts[0], out long instance) || !int.TryParse(parts[1], out int id) || parts.Skip(2).Any(part => !int.TryParse(part, out _)))
				return new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
			result.Items.Add(new BattleConfigurationItem { Id = id, InstanceId = instance, Details = "等级：" + obj["l"] });
		}
		result.State = result.Items.Any(item => item.Id > 0) ? BattleConfigurationState.Known : BattleConfigurationState.Empty;
		return result;
	}

	private static BattleConfigurationGroup ReadAttribute(string raw, int category)
	{
		var result = new BattleConfigurationGroup { State = BattleConfigurationState.Empty };
		if (raw.Length == 0) return result;
		foreach (string entry in raw.Split(category == 0 ? '#' : category == 1 ? '|' : '_'))
		{
			var item = new BattleConfigurationItem();
			if (entry.Length != 0)
			{
				string[] parts = entry.Split(category == 0 ? ':' : ';');
				int index = category == 2 ? 0 : 1;
				if (parts.Length <= index || !int.TryParse(parts[index], NumberStyles.Integer, CultureInfo.InvariantCulture, out int id))
					return new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
				item.Id = Math.Max(0, id);
				if (category == 0) item.Details = "槽位等级：" + parts[0];
				if (category == 1)
				{
					if (parts.Length < 3 || !long.TryParse(parts[0], out long instance)) return new BattleConfigurationGroup { State = BattleConfigurationState.Invalid };
					item.InstanceId = instance;
					item.Details = parts[2];
				}
			}
			result.Items.Add(item);
		}
		result.State = result.Items.Any(item => item.Id > 0) ? BattleConfigurationState.Known : BattleConfigurationState.Empty;
		return result;
	}
}
