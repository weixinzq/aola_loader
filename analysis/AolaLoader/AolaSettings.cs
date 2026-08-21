using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Newtonsoft.Json;

namespace AolaLoader;

/// <summary>
/// 程序设置：主题选择与形态变化规则，保存到可执行文件旁的 settings.json。
/// </summary>
internal sealed class AolaAppSettings
{
	public int SchemaVersion { get; set; } = 5;

	public int SelectedThemeId { get; set; }

	public bool PetMorphEnabled { get; set; }

	public bool PetMorphLiveBridgeEnabled { get; set; } = true;

	public List<AolaPetMorphRuleData> PetMorphRules { get; set; } = new List<AolaPetMorphRuleData>();
}

internal sealed class AolaPetMorphRuleData
{
	public string Note { get; set; }

	public int OriginalId { get; set; }

	public int BackpackId { get; set; }

	public int PosterSourceId { get; set; }

	public int PosterId { get; set; }

	public bool HideOriginalModel { get; set; }

	public bool RemoveOriginalBackground { get; set; }

	public bool ReplaceBackpackIcon { get; set; }
}

internal sealed class AolaSettingsStore
{
	private readonly string _path;

	public AolaSettingsStore(string path)
	{
		_path = path ?? throw new ArgumentNullException(nameof(path));
	}

	public AolaAppSettings Load()
	{
		AolaAppSettings settings = new AolaAppSettings();
		try
		{
			if (!File.Exists(_path))
			{
				return settings;
			}
			AolaAppSettings loaded = JsonConvert.DeserializeObject<AolaAppSettings>(
				File.ReadAllText(_path, Encoding.UTF8));
			if (loaded == null)
			{
				return settings;
			}
			loaded.PetMorphRules = loaded.PetMorphRules ?? new List<AolaPetMorphRuleData>();
			loaded.PetMorphRules.RemoveAll(item => item == null ||
				(item.OriginalId <= 0 && item.PosterSourceId <= 0));
			loaded.SchemaVersion = 5;
			return loaded;
		}
		catch (Exception ex) when (ex is IOException || ex is UnauthorizedAccessException || ex is JsonException || ex is ArgumentException)
		{
			return settings;
		}
	}

	public void Save(AolaAppSettings settings)
	{
		if (settings == null)
		{
			throw new ArgumentNullException(nameof(settings));
		}
		string directory = Path.GetDirectoryName(_path);
		if (!string.IsNullOrEmpty(directory))
		{
			Directory.CreateDirectory(directory);
		}
		File.WriteAllText(
			_path,
			JsonConvert.SerializeObject(settings, Formatting.Indented),
			new UTF8Encoding(false));
	}
}
