using System;
using System.IO;
using System.Text;
using Newtonsoft.Json.Linq;
namespace AolaLoader.Features.Battle.Data;
internal sealed class BattleConfigurationCatalog
{
	private readonly JObject _entries;
	public BattleConfigurationCatalog()
	{
		string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "BattleAssistant", "catalog.json");
		try { _entries = File.Exists(path) ? JObject.Parse(File.ReadAllText(path)) : new JObject(); }
		catch (IOException) { _entries = new JObject(); }
		catch (Newtonsoft.Json.JsonException) { _entries = new JObject(); }
	}
	public string Describe(string category, int id)
	{
		JToken entry = _entries[category + ":" + id];
		return entry == null ? "未知配置，待补充资料" : (string)entry["name"] + "\n" + (string)entry["description"];
	}
	public string DescribeActualArtifactEntries(string raw)
	{
		var text = new StringBuilder();
		foreach (string entry in (raw ?? "").Split('#'))
		{
			string[] parts = entry.Split(':');
			if (parts.Length != 2 || !int.TryParse(parts[0], out int id) || !int.TryParse(parts[1], out int level)) continue;
			string name = (string)_entries["tote-entry:" + id]?["name"];
			text.AppendLine((name ?? "未知词条") + " · 等级 " + level);
		}
		return text.ToString().TrimEnd();
	}
}
