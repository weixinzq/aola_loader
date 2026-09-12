using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Lineup;

internal sealed class LineupPreset
{
	public int SchemaVersion { get; set; } = 1;
	public string Name { get; set; } = "阵容方案";
	public DateTimeOffset SavedAt { get; set; } = DateTimeOffset.Now;
	public long OwnerPlayerId { get; set; }
	public List<LineupPet> Pets { get; set; } = new List<LineupPet>();
}

internal sealed class LineupPet
{
	public int PetId { get; set; }
	public int RaceId { get; set; }
	public string Name { get; set; }
	public int[] SoulCards { get; set; }
	public LineupArtifact[] SoulArtifacts { get; set; }
	public int[] CrystalKeys { get; set; }
}

internal sealed class LineupArtifact
{
	public int InstanceId { get; set; }
	public int ConfigId { get; set; }
}

internal static class LineupPresetStore
{
	private static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
	{
		ContractResolver = new Newtonsoft.Json.Serialization.CamelCasePropertyNamesContractResolver(),
		MissingMemberHandling = MissingMemberHandling.Error,
		TypeNameHandling = TypeNameHandling.None,
		MaxDepth = 16
	};

	public static LineupPreset Load(string path)
	{
		if (new FileInfo(path).Length > 1024 * 1024) throw new InvalidDataException("方案文件超过 1 MiB。");
		JObject json = JObject.Parse(File.ReadAllText(path, Encoding.UTF8), new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
		RequireInteger(json["schemaVersion"], "schemaVersion");
		RequireInteger(json["ownerPlayerId"], "ownerPlayerId");
		if (!(json["pets"] is JArray pets)) throw new InvalidDataException("缺少 pets 数组。");
		foreach (JToken entry in pets)
		{
			if (!(entry is JObject pet)) throw new InvalidDataException("亚比条目必须为对象。");
			RequireInteger(pet["petId"], "petId");
			RequireInteger(pet["raceId"], "raceId");
			foreach (string field in new[] { "soulCards", "soulArtifacts", "crystalKeys" })
			{
				JToken value = pet[field];
				if (value == null || (value.Type != JTokenType.Null && !(value is JArray))) throw new InvalidDataException(field + " 必须为数组或 null。");
				if (!(value is JArray array)) continue;
				foreach (JToken item in array)
				{
					if (field != "soulArtifacts") RequireInteger(item, field);
					else if (item.Type != JTokenType.Null)
					{
						if (!(item is JObject artifact)) throw new InvalidDataException("魂器条目无效。");
						RequireInteger(artifact["instanceId"], "instanceId");
						RequireInteger(artifact["configId"], "configId");
					}
				}
			}
		}
		LineupPreset preset = json.ToObject<LineupPreset>(JsonSerializer.Create(Settings));
		Validate(preset);
		return preset;
	}

	private static void RequireInteger(JToken value, string field)
	{
		if (value?.Type != JTokenType.Integer) throw new InvalidDataException(field + " 必须为整数。");
	}

	public static void Validate(LineupPreset preset)
	{
		if (preset == null || preset.SchemaVersion != 1 || preset.OwnerPlayerId <= 0 || string.IsNullOrWhiteSpace(preset.Name) || preset.Name.Length > 100)
			throw new InvalidDataException("方案版本、名称或所属玩家编号无效。");
		if (preset.Pets == null || preset.Pets.Count < 1 || preset.Pets.Count > 6) throw new InvalidDataException("方案必须包含 1 至 6 只亚比。");
		var pets = new HashSet<int>();
		var artifacts = new HashSet<int>();
		foreach (LineupPet pet in preset.Pets)
		{
			if (pet == null || pet.PetId <= 0 || pet.RaceId <= 0 || !pets.Add(pet.PetId)) throw new InvalidDataException("亚比编号无效或重复。");
			if (pet.SoulCards != null && (pet.SoulCards.Length != 5 || pet.SoulCards.Any(id => id < 0))) throw new InvalidDataException("魂卡必须为五个非负编号。");
			if (pet.CrystalKeys != null && (pet.CrystalKeys.Length != 2 || pet.CrystalKeys.Any(id => id < 0))) throw new InvalidDataException("晶钥必须为两个非负编号。");
			if (pet.SoulArtifacts == null) continue;
			if (pet.SoulArtifacts.Length != 2) throw new InvalidDataException("魂器必须保留两个槽位。");
			foreach (LineupArtifact item in pet.SoulArtifacts.Where(item => item != null))
				if (item.InstanceId <= 0 || item.ConfigId <= 0 || !artifacts.Add(item.InstanceId)) throw new InvalidDataException("魂器实例无效或被方案重复分配。");
		}
	}

	public static void Save(string path, LineupPreset preset)
	{
		Validate(preset);
		string target = Path.GetFullPath(path);
		string temporary = target + "." + Guid.NewGuid().ToString("N") + ".tmp";
		try
		{
			File.WriteAllText(temporary, JsonConvert.SerializeObject(preset, Newtonsoft.Json.Formatting.Indented, Settings), new UTF8Encoding(false));
			if (File.Exists(target)) File.Replace(temporary, target, null);
			else File.Move(temporary, target);
		}
		finally { if (File.Exists(temporary)) File.Delete(temporary); }
	}
}

internal static class LineupPetParser
{
	public static JObject View(JObject pet) => (pet["pmPView"] ?? pet["pmSView"]) as JObject ?? throw new InvalidDataException("缺少亚比资料。");
	public static LineupPet Parse(JObject pet)
	{
		JObject view = View(pet);
		var result = new LineupPet { PetId = view.Value<int>("i"), RaceId = view.Value<int>("r"), Name = view.Value<string>("nm") };
		if (view["pcp"]?.Type != JTokenType.String) throw new InvalidDataException("亚比 " + result.PetId + " 缺少配置资料。");
		var xml = new XmlDocument { XmlResolver = null };
		using (var reader = XmlReader.Create(new StringReader((string)view["pcp"]), new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null })) xml.Load(reader);
		XmlElement root = xml.DocumentElement;
		if (root == null || root.Name != "p") throw new InvalidDataException("亚比配置格式无效。");
		if (root.HasAttribute("soc")) result.SoulCards = root.GetAttribute("soc").Split('#').Select(item =>
		{
			string[] fields = item.Split(':');
			if (fields.Length != 2) throw new InvalidDataException("魂卡配置格式无效。");
			return int.Parse(fields[1]);
		}).ToArray();
		if (root.HasAttribute("ctk")) result.CrystalKeys = root.GetAttribute("ctk").Split('_').Select(int.Parse).ToArray();
		if (root.HasAttribute("tt")) result.SoulArtifacts = root.GetAttribute("tt").Split('|').Select(item =>
		{
			if (item.Length == 0) return null;
			string[] fields = item.Split(';');
			if (fields.Length < 3) throw new InvalidDataException("魂器配置格式无效。");
			return new LineupArtifact { InstanceId = int.Parse(fields[0]), ConfigId = int.Parse(fields[1]) };
		}).ToArray();
		return result;
	}
}

