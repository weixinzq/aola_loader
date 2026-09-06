using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class BattlePetMovieVersionCatalog
{
	private static readonly Regex PathPattern = new Regex(
		@"^fightassets/bitmap/pet\d+/pet\d+_[12]_[0-2]$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private readonly IReadOnlyDictionary<string, string> _versions;

	private BattlePetMovieVersionCatalog(
		string versionDataVersion,
		string versionDataSha256,
		string defaultVersion,
		IReadOnlyDictionary<string, string> versions,
		string error)
	{
		VersionDataVersion = versionDataVersion ?? string.Empty;
		VersionDataSha256 = versionDataSha256 ?? string.Empty;
		DefaultVersion = defaultVersion ?? string.Empty;
		_versions = versions ?? new Dictionary<string, string>();
		Error = error;
	}

	public string VersionDataVersion { get; }
	public string VersionDataSha256 { get; }
	public string DefaultVersion { get; }
	public string Error { get; }
	public bool IsAvailable => Error == null;

	public string GetVersion(string path)
	{
		if (!IsAvailable || string.IsNullOrWhiteSpace(path) || !PathPattern.IsMatch(path))
		{
			return null;
		}
		return _versions.TryGetValue(path, out string version) ? version : DefaultVersion;
	}

	public static BattlePetMovieVersionCatalog Load(string path)
	{
		try
		{
			if (!File.Exists(path)) return Empty("找不到战斗模型版本目录：" + path);
			JObject root = JObject.Parse(File.ReadAllText(path));
			string[] fields = { "schemaVersion", "versionDataVersion", "versionDataSha256", "defaultVersion", "entries" };
			if (root.Properties().Any(property => !fields.Contains(property.Name, StringComparer.Ordinal)) ||
				root.Count != fields.Length || root["schemaVersion"]?.Type != JTokenType.Integer ||
				root.Value<int>("schemaVersion") != 1 || root["versionDataVersion"]?.Type != JTokenType.String ||
				root["versionDataSha256"]?.Type != JTokenType.String || root["defaultVersion"]?.Type != JTokenType.String ||
				!(root["entries"] is JObject entries))
			{
				return Empty("战斗模型版本目录结构无效。");
			}
			string versionDataVersion = root.Value<string>("versionDataVersion");
			string sha256 = root.Value<string>("versionDataSha256");
			string defaultVersion = root.Value<string>("defaultVersion");
			if (!IsDigits(versionDataVersion) || !Regex.IsMatch(sha256 ?? string.Empty, "^[0-9a-f]{64}$") ||
				!IsDigits(defaultVersion))
			{
				return Empty("战斗模型版本目录元数据无效。");
			}
			Dictionary<string, string> versions = new Dictionary<string, string>(StringComparer.Ordinal);
			foreach (JProperty property in entries.Properties())
			{
				if (!PathPattern.IsMatch(property.Name) || property.Value.Type != JTokenType.String ||
					!IsDigits(property.Value.Value<string>()) || versions.ContainsKey(property.Name))
				{
					return Empty("战斗模型版本目录包含无效或重复条目。");
				}
				versions.Add(property.Name, property.Value.Value<string>());
			}
			return new BattlePetMovieVersionCatalog(versionDataVersion, sha256, defaultVersion, versions, null);
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException ||
			ex is JsonException || ex is ArgumentException || ex is InvalidOperationException)
		{
			return Empty("读取战斗模型版本目录失败：" + ex.Message);
		}
	}

	private static bool IsDigits(string value) =>
		!string.IsNullOrEmpty(value) && value.All(character => character >= '0' && character <= '9');

	private static BattlePetMovieVersionCatalog Empty(string error) =>
		new BattlePetMovieVersionCatalog(null, null, null, null, error);
}
