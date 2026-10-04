using System;
using System.IO;
using System.Linq;
using System.Text;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.Coordination.Testing;
using AolaLoader.Features.Theme.Settings;
using AolaLoader.Settings;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class ThemeCoordinatorVerifier
{
	public static bool Verify()
	{
		string root = Path.Combine(Path.GetTempPath(), "aola-theme-coordinator-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(root);
		try
		{
			return VerifyDefaultsAndOptions(root) &&
				VerifyApplyToRule(root) &&
				VerifyApplyAndSavePreservesUnknownFields(root) &&
				VerifyRuleRejectionDoesNotSave(root) &&
				VerifySaveFailurePreservesFileAndSnapshot(root) &&
				VerifyRestoreFromSavedSection(root) && VerifyTheme10LegacyMode(root);
		}
		finally
		{
			try
			{
				Directory.Delete(root, recursive: true);
			}
			catch (IOException)
			{
			}
			catch (UnauthorizedAccessException)
			{
			}
		}
	}

	private static bool VerifyDefaultsAndOptions(string root)
	{
		string missingPath = Path.Combine(root, "missing.json");
		ManualThemeSelectionTarget target = new ManualThemeSelectionTarget();
		ThemeCoordinator coordinator = new ThemeCoordinator(
			new JsonSettingsSectionStore(missingPath),
			new ThemeSettingsCodec(),
			target);
		return coordinator.Current.SelectedThemeId == 0 &&
			coordinator.Options.Count == 10 &&
			coordinator.Options[0].Id == 0 &&
			coordinator.Options[0].DisplayName == "默认" &&
			coordinator.Options[9].Id == 9 &&
			target.AppliedIds.Count == 0 &&
			!File.Exists(missingPath);
	}

	private static bool VerifyApplyToRule(string root)
	{
		string path = Path.Combine(root, "apply-rule.json");
		ManualThemeSelectionTarget target = new ManualThemeSelectionTarget();
		ThemeCoordinator coordinator = new ThemeCoordinator(
			new JsonSettingsSectionStore(path),
			new ThemeSettingsCodec(),
			target);
		ThemeChangeResult applied = coordinator.ApplyToRule(4);
		if (!applied.RuleApplied || applied.SettingsSaved ||
			applied.AppliedThemeId != 4 || !target.AppliedIds.SequenceEqual(new[] { 4 }) ||
			File.Exists(path))
		{
			return false;
		}

		ThemeChangeResult defaulted = coordinator.ApplyToRule(0);
		if (!defaulted.RuleApplied || defaulted.SettingsSaved || defaulted.AppliedThemeId != 0 ||
			target.LastAppliedId != 0)
		{
			return false;
		}

		ThemeChangeResult clamped = coordinator.ApplyToRule(99);
		return clamped.RuleApplied && !clamped.SettingsSaved &&
			clamped.AppliedThemeId == 0 && target.LastAppliedId == 0;
	}

	private static bool VerifyApplyAndSavePreservesUnknownFields(string root)
	{
		string path = Path.Combine(root, "apply-save.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject
				{
					["Version"] = 1,
					["SelectedThemeId"] = 1,
					["UnknownThemeField"] = "keep"
				}
			}
		});
		ManualThemeSelectionTarget target = new ManualThemeSelectionTarget();
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		ThemeCoordinator coordinator = new ThemeCoordinator(store, new ThemeSettingsCodec(), target);
		if (coordinator.Current.SelectedThemeId != 1)
		{
			return false;
		}

		ThemeChangeResult result = coordinator.ApplyAndSave(6);
		if (!result.Succeeded || result.AppliedThemeId != 6 || target.LastAppliedId != 6 ||
			coordinator.Current.SelectedThemeId != 6)
		{
			return false;
		}

		JObject document = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject theme = (JObject)document["Sections"]["theme"];
		if (theme.Value<int>("Version") != 1 || theme.Value<int>("SelectedThemeId") != 6 ||
			theme.Value<string>("UnknownThemeField") != "keep" || HasUtf8Bom(path))
		{
			return false;
		}

		ThemeCoordinator reloaded = new ThemeCoordinator(
			store,
			new ThemeSettingsCodec(),
			new ManualThemeSelectionTarget());
		return reloaded.Current.SelectedThemeId == 6;
	}

	private static bool VerifyRuleRejectionDoesNotSave(string root)
	{
		string path = Path.Combine(root, "rule-reject.json");
		RejectingThemeSelectionTarget target = new RejectingThemeSelectionTarget();
		ThemeCoordinator coordinator = new ThemeCoordinator(
			new JsonSettingsSectionStore(path),
			new ThemeSettingsCodec(),
			target);
		ThemeChangeResult result = coordinator.ApplyAndSave(5);
		return !result.RuleApplied && !result.Succeeded && !string.IsNullOrWhiteSpace(result.Error) &&
			!File.Exists(path) && target.Calls.Count == 1 && target.Calls[0] == 5;
	}

	private static bool VerifySaveFailurePreservesFileAndSnapshot(string root)
	{
		string path = Path.Combine(root, "save-fail.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject { ["Version"] = 1, ["SelectedThemeId"] = 1 }
			}
		});
		byte[] before = File.ReadAllBytes(path);
		ManualThemeSelectionTarget target = new ManualThemeSelectionTarget();
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(
			path,
			new FailingSettingsWriter(),
			new LegacySettingsMigrator());
		ThemeCoordinator coordinator = new ThemeCoordinator(store, new ThemeSettingsCodec(), target);
		ThemeChangeResult result = coordinator.ApplyAndSave(3);
		return result.RuleApplied && !result.SettingsSaved && !result.Succeeded &&
			!string.IsNullOrWhiteSpace(result.Error) &&
			target.LastAppliedId == 3 &&
			coordinator.Current.SelectedThemeId == 1 &&
			before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static bool VerifyRestoreFromSavedSection(string root)
	{
		string path = Path.Combine(root, "restore.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject { ["Version"] = 1, ["SelectedThemeId"] = 2 }
			}
		});
		ManualThemeSelectionTarget target = new ManualThemeSelectionTarget();
		ThemeCoordinator coordinator = new ThemeCoordinator(
			new JsonSettingsSectionStore(path),
			new ThemeSettingsCodec(),
			target);
		ThemeChangeResult restored = coordinator.ApplyToRule(coordinator.Current.SelectedThemeId);
		return restored.RuleApplied && restored.AppliedThemeId == 2 && target.LastAppliedId == 2;
	}

	private static bool HasUtf8Bom(string path)
	{
		byte[] bytes = File.ReadAllBytes(path);
		return bytes.Length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf;
	}

	private static bool VerifyTheme10LegacyMode(string root)
	{
		string path = Path.Combine(root, "theme10.json");
		WriteJson(path, new JObject { ["DocumentVersion"] = 1, ["Sections"] = new JObject
		{
			["theme"] = new JObject { ["Version"] = 1, ["SelectedThemeId"] = 10, ["UnknownThemeField"] = "keep" }
		} });
		byte[] before = File.ReadAllBytes(path);
		var codec = new ThemeSettingsCodec();
		var target = new ManualThemeSelectionTarget();
		var coordinator = new ThemeCoordinator(new JsonSettingsSectionStore(path), codec, target);
		return codec.Normalize(new ThemeSettings(10)).SelectedThemeId == 10 &&
			codec.Serialize(new ThemeSettings(10)).Value<int>("SelectedThemeId") == 10 &&
			codec.Serialize(new ThemeSettings(10)).Value<int>("Version") == 1 &&
			codec.Normalize(new ThemeSettings(11)).SelectedThemeId == 0 &&
			coordinator.Current.SelectedThemeId == 10 && coordinator.Options.All(option => option.Id != 10) &&
			!coordinator.ApplyToRule(10).RuleApplied && !coordinator.ApplyAndSave(10).Succeeded &&
			coordinator.PushCurrentAsync(System.Threading.CancellationToken.None).GetAwaiter().GetResult().Status == "Unavailable" &&
			target.AppliedIds.Count == 0 && before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static void WriteJson(string path, JObject value)
	{
		File.WriteAllText(
			path,
			JsonConvert.SerializeObject(value, Formatting.Indented),
			new UTF8Encoding(false));
	}

	private sealed class FailingSettingsWriter : IAtomicSettingsWriter
	{
		public void WriteAllText(string path, string content)
		{
			throw new IOException("Simulated interrupted theme settings save.");
		}
	}

	private sealed class RejectingThemeSelectionTarget : IThemeSelectionTarget
	{
		private readonly System.Collections.Generic.List<int> _calls =
			new System.Collections.Generic.List<int>();

		public System.Collections.Generic.IReadOnlyList<int> Calls => _calls;

		public void SetSelectedThemeId(int themeId)
		{
			_calls.Add(themeId);
			if (themeId != 0)
			{
				throw new InvalidOperationException("Theme " + themeId + " does not have a verified local SWF.");
			}
		}
	}
}
