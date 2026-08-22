using System;
using System.IO;
using System.Linq;
using System.Text;
using AolaLoader.Features.PetMorph.Settings;
using AolaLoader.Features.Theme.Settings;
using AolaLoader.Settings;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class SettingsBoundaryVerifier
{
	public static bool Verify()
	{
		string root = Path.Combine(Path.GetTempPath(), "aola-settings-verify-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(root);
		try
		{
			return VerifyMissingAndRoundTrip(root) &&
				VerifyTypedThemeSettingsAndLegacyMigration(root) &&
				VerifyTypedPetMorphSettings(root) &&
				VerifyProductionThemeAndPetMorphMigration(root) &&
				VerifyUnknownContentAndIndependentUpdates(root) &&
				VerifyCorruptSectionIsolation(root) &&
				VerifyLegacyMigration(root) &&
				VerifyMigrationFailurePreservesEvidence(root) &&
				VerifyCodecMigrationFailurePreservesEvidence(root) &&
				VerifyInterruptedSavePreservesFile(root);
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

	private static bool VerifyTypedPetMorphSettings(string root)
	{
		string path = Path.Combine(root, "typed-petmorph.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = true,
					["UnknownPetMorphField"] = "keep",
					["Rules"] = new JArray
					{
						new JObject
						{
							["OriginalId"] = 5486,
							["BackpackId"] = 5530,
							["FutureRuleField"] = 91
						},
						new JObject { ["OriginalId"] = 0, ["PosterSourceId"] = 0 }
					}
				}
			}
		});
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		PetMorphSettingsCodec codec = new PetMorphSettingsCodec();
		SettingsSectionLoadResult<PetMorphSettings> loaded =
			store.Load(PetMorphSettingsCodec.SectionKey, codec);
		if (loaded.UsedDefault || !loaded.Value.Enabled || !loaded.Value.LiveBridgeEnabled ||
			loaded.Value.Rules.Count != 1 || loaded.Value.Rules[0].OriginalId != 5486 ||
			loaded.Value.Rules[0].HideOriginalModel)
		{
			return false;
		}
		if (!store.Save(
			PetMorphSettingsCodec.SectionKey,
			new PetMorphSettings(false, loaded.Value.LiveBridgeEnabled, loaded.Value.Rules),
			codec).Succeeded)
		{
			return false;
		}
		JObject saved = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject section = (JObject)saved["Sections"]["petMorph"];
		JObject savedRule = (JObject)((JArray)section["Rules"])[0];
		if (section.Value<string>("UnknownPetMorphField") != "keep" ||
			savedRule.Value<int>("FutureRuleField") != 91 || section.Value<bool>("Enabled"))
		{
			return false;
		}

		string invalidPath = Path.Combine(root, "typed-petmorph-invalid.json");
		WriteJson(invalidPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = "invalid",
					["Rules"] = new JArray()
				}
			}
		});
		byte[] before = File.ReadAllBytes(invalidPath);
		SettingsSectionLoadResult<PetMorphSettings> invalid =
			new JsonSettingsSectionStore(invalidPath).Load(PetMorphSettingsCodec.SectionKey, codec);
		return invalid.UsedDefault && !string.IsNullOrWhiteSpace(invalid.Error) &&
			!invalid.Value.Enabled && invalid.Value.LiveBridgeEnabled &&
			before.SequenceEqual(File.ReadAllBytes(invalidPath));
	}

	private static bool VerifyProductionThemeAndPetMorphMigration(string root)
	{
		string path = Path.Combine(root, "production-theme-transition.json");
		WriteJson(path, new JObject
		{
			["SchemaVersion"] = 5,
			["SelectedThemeId"] = 4,
			["PetMorphEnabled"] = true,
			["PetMorphLiveBridgeEnabled"] = false,
			["PetMorphRules"] = new JArray
			{
				new JObject
				{
					["Note"] = "transition",
					["OriginalId"] = 5486,
					["BackpackId"] = 5530
				}
			},
			["FutureRoot"] = "keep"
		});

		JsonSettingsSectionStore sections = new JsonSettingsSectionStore(path);
		ThemeSettingsCodec themeCodec = new ThemeSettingsCodec();
		PetMorphSettingsCodec petMorphCodec = new PetMorphSettingsCodec();
		SettingsSectionLoadResult<ThemeSettings> theme =
			sections.Load(ThemeSettingsCodec.SectionKey, themeCodec);
		SettingsSectionLoadResult<PetMorphSettings> petMorph =
			sections.Load(PetMorphSettingsCodec.SectionKey, petMorphCodec);
		if (theme.UsedDefault || theme.Value.SelectedThemeId != 4 ||
			petMorph.UsedDefault || !petMorph.Value.Enabled || petMorph.Value.LiveBridgeEnabled ||
			petMorph.Value.Rules.Count != 1 ||
			!sections.Save(ThemeSettingsCodec.SectionKey, new ThemeSettings(2), themeCodec).Succeeded)
		{
			return false;
		}

		PetMorphRuleSettings retainedRule = petMorph.Value.Rules[0];
		if (!sections.Save(
			PetMorphSettingsCodec.SectionKey,
			new PetMorphSettings(false, true, new[] { retainedRule }),
			petMorphCodec).Succeeded)
		{
			return false;
		}
		JObject document = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		return document.Value<int>("DocumentVersion") == 1 &&
			document.Value<string>("FutureRoot") == "keep" &&
			document["Sections"]["theme"].Value<int>("SelectedThemeId") == 2 &&
			!document["Sections"]["petMorph"].Value<bool>("Enabled") &&
			document["Sections"]["petMorph"].Value<bool>("LiveBridgeEnabled") &&
			((JArray)document["Sections"]["petMorph"]["Rules"]).Count == 1 &&
			document["Sections"]["battle"] is JObject && !HasUtf8Bom(path);
	}

	private static bool VerifyTypedThemeSettingsAndLegacyMigration(string root)
	{
		ThemeSettingsCodec codec = new ThemeSettingsCodec();
		string missingPath = Path.Combine(root, "typed-theme-missing.json");
		SettingsSectionLoadResult<ThemeSettings> missing =
			new JsonSettingsSectionStore(missingPath).Load(ThemeSettingsCodec.SectionKey, codec);
		if (!missing.UsedDefault || missing.Value.SelectedThemeId != 0 ||
			codec.Normalize(new ThemeSettings(-1)).SelectedThemeId != 0 ||
			codec.Normalize(new ThemeSettings(10)).SelectedThemeId != 0)
		{
			return false;
		}

		string legacyPath = Path.Combine(root, "typed-theme-legacy.json");
		WriteJson(legacyPath, new JObject
		{
			["SchemaVersion"] = 5,
			["SelectedThemeId"] = 4,
			["PetMorphEnabled"] = false,
			["PetMorphLiveBridgeEnabled"] = true,
			["PetMorphRules"] = new JArray(),
			["FutureRoot"] = new JObject { ["Value"] = 17 }
		});
		JsonSettingsSectionStore legacyStore = new JsonSettingsSectionStore(legacyPath);
		SettingsSectionLoadResult<ThemeSettings> migrated =
			legacyStore.Load(ThemeSettingsCodec.SectionKey, codec);
		if (migrated.UsedDefault || !migrated.LegacyDocumentMigrated ||
			migrated.Value.SelectedThemeId != 4 || HasUtf8Bom(legacyPath))
		{
			return false;
		}
		if (!legacyStore.Save(ThemeSettingsCodec.SectionKey, new ThemeSettings(3), codec).Succeeded)
		{
			return false;
		}
		JObject saved = JObject.Parse(File.ReadAllText(legacyPath, Encoding.UTF8));
		if (saved["FutureRoot"].Value<int>("Value") != 17 ||
			saved["Sections"]["theme"].Value<int>("Version") != 1 ||
			saved["Sections"]["theme"].Value<int>("SelectedThemeId") != 3 ||
			!(saved["Sections"]["petMorph"] is JObject) ||
			!(saved["Sections"]["battle"] is JObject))
		{
			return false;
		}

		string invalidPath = Path.Combine(root, "typed-theme-invalid.json");
		WriteJson(invalidPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject
				{
					["Version"] = 2,
					["SelectedThemeId"] = "invalid"
				}
			}
		});
		byte[] invalidBefore = File.ReadAllBytes(invalidPath);
		SettingsSectionLoadResult<ThemeSettings> invalid =
			new JsonSettingsSectionStore(invalidPath).Load(ThemeSettingsCodec.SectionKey, codec);
		return invalid.UsedDefault && !string.IsNullOrWhiteSpace(invalid.Error) &&
			invalid.Value.SelectedThemeId == 0 && invalidBefore.SequenceEqual(File.ReadAllBytes(invalidPath));
	}

	private static bool VerifyMissingAndRoundTrip(string root)
	{
		string path = Path.Combine(root, "missing.json");
		JObjectCodec themeCodec = CreateThemeCodec();
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		SettingsSectionLoadResult<JObject> missing = store.Load("theme", themeCodec);
		if (!missing.UsedDefault || missing.Error != null || missing.Value.Value<int>("SelectedThemeId") != 0)
		{
			return false;
		}

		SettingsSectionSaveResult saved = store.Save(
			"theme",
			new JObject { ["Version"] = 1, ["SelectedThemeId"] = 3 },
			themeCodec);
		if (!saved.Succeeded || HasUtf8Bom(path))
		{
			return false;
		}

		SettingsSectionLoadResult<JObject> loaded = store.Load("theme", themeCodec);
		loaded.Value["SelectedThemeId"] = 9;
		SettingsSectionLoadResult<JObject> loadedAgain = store.Load("theme", themeCodec);
		return !loaded.UsedDefault && loadedAgain.Value.Value<int>("SelectedThemeId") == 3;
	}

	private static bool VerifyUnknownContentAndIndependentUpdates(string root)
	{
		string path = Path.Combine(root, "unknown.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["UnknownRoot"] = "keep-root",
			["Sections"] = new JObject
			{
				["theme"] = new JObject
				{
					["Version"] = 1,
					["SelectedThemeId"] = 2,
					["UnknownThemeField"] = "keep-theme"
				},
				["futureModule"] = new JObject { ["Version"] = 7, ["Value"] = 99 }
			}
		});

		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		if (!store.Save(
			"theme",
			new JObject { ["Version"] = 1, ["SelectedThemeId"] = 7 },
			CreateThemeCodec()).Succeeded)
		{
			return false;
		}
		if (!store.Save(
			"petMorph",
			new JObject
			{
				["Version"] = 1,
				["Enabled"] = true,
				["LiveBridgeEnabled"] = true,
				["Rules"] = new JArray()
			},
			CreatePetMorphCodec()).Succeeded)
		{
			return false;
		}

		JObject document = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject sections = (JObject)document["Sections"];
		return document.Value<string>("UnknownRoot") == "keep-root" &&
			sections["futureModule"].Value<int>("Value") == 99 &&
			sections["theme"].Value<int>("SelectedThemeId") == 7 &&
			sections["theme"].Value<string>("UnknownThemeField") == "keep-theme" &&
			sections["petMorph"].Value<bool>("Enabled");
	}

	private static bool VerifyCorruptSectionIsolation(string root)
	{
		string path = Path.Combine(root, "corrupt-section.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = "not-an-object",
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = true,
					["LiveBridgeEnabled"] = false,
					["Rules"] = new JArray()
				}
			}
		});

		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		SettingsSectionLoadResult<JObject> theme = store.Load("theme", CreateThemeCodec());
		SettingsSectionLoadResult<JObject> petMorph = store.Load("petMorph", CreatePetMorphCodec());
		return theme.UsedDefault && !string.IsNullOrWhiteSpace(theme.Error) &&
			!petMorph.UsedDefault && petMorph.Value.Value<bool>("Enabled");
	}

	private static bool VerifyLegacyMigration(string root)
	{
		string path = Path.Combine(root, "legacy.json");
		WriteJson(path, new JObject
		{
			["SchemaVersion"] = 5,
			["SelectedThemeId"] = 4,
			["PetMorphEnabled"] = true,
			["PetMorphRules"] = new JArray
			{
				new JObject
				{
					["Note"] = "legacy",
					["OriginalId"] = 6000,
					["BackpackId"] = 6047
				}
			},
			["UnknownLegacyField"] = "keep-legacy"
		});

		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		SettingsSectionLoadResult<JObject> theme = store.Load("theme", CreateThemeCodec());
		if (theme.UsedDefault || !theme.LegacyDocumentMigrated ||
			theme.Value.Value<int>("SelectedThemeId") != 4 || HasUtf8Bom(path))
		{
			return false;
		}

		JObject migrated = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject sections = (JObject)migrated["Sections"];
		JObject petMorph = (JObject)sections["petMorph"];
		JObject rule = (JObject)((JArray)petMorph["Rules"])[0];
		return migrated.Value<int>("DocumentVersion") == 1 &&
			migrated.Value<string>("UnknownLegacyField") == "keep-legacy" &&
			petMorph.Value<bool>("Enabled") &&
			petMorph.Value<bool>("LiveBridgeEnabled") &&
			!rule.Value<bool>("HideOriginalModel") &&
			!rule.Value<bool>("RemoveOriginalBackground") &&
			!rule.Value<bool>("ReplaceBackpackIcon") &&
			sections["battle"] is JObject;
	}

	private static bool VerifyMigrationFailurePreservesEvidence(string root)
	{
		string path = Path.Combine(root, "bad-legacy.json");
		WriteJson(path, new JObject
		{
			["SchemaVersion"] = 5,
			["PetMorphEnabled"] = "invalid",
			["PetMorphRules"] = new JArray()
		});
		byte[] before = File.ReadAllBytes(path);
		SettingsSectionLoadResult<JObject> result =
			new JsonSettingsSectionStore(path).Load("theme", CreateThemeCodec());
		return result.UsedDefault && !string.IsNullOrWhiteSpace(result.Error) &&
			before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static bool VerifyInterruptedSavePreservesFile(string root)
	{
		string path = Path.Combine(root, "save-failure.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject { ["Version"] = 1, ["SelectedThemeId"] = 1 }
			}
		});
		byte[] before = File.ReadAllBytes(path);
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(
			path,
			new FailingSettingsWriter(),
			new LegacySettingsMigrator());
		SettingsSectionSaveResult result = store.Save(
			"theme",
			new JObject { ["Version"] = 1, ["SelectedThemeId"] = 8 },
			CreateThemeCodec());
		return !result.Succeeded && !string.IsNullOrWhiteSpace(result.Error) &&
			before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static bool VerifyCodecMigrationFailurePreservesEvidence(string root)
	{
		string path = Path.Combine(root, "codec-rejected-legacy.json");
		WriteJson(path, new JObject
		{
			["SchemaVersion"] = 5,
			["SelectedThemeId"] = 2,
			["PetMorphEnabled"] = false,
			["PetMorphLiveBridgeEnabled"] = true,
			["PetMorphRules"] = new JArray()
		});
		byte[] before = File.ReadAllBytes(path);
		SettingsSectionLoadResult<JObject> result =
			new JsonSettingsSectionStore(path).Load("theme", new RejectingCodec());
		return result.UsedDefault && !string.IsNullOrWhiteSpace(result.Error) &&
			before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static JObjectCodec CreateThemeCodec()
	{
		return new JObjectCodec(() => new JObject
		{
			["Version"] = 1,
			["SelectedThemeId"] = 0
		});
	}

	private static JObjectCodec CreatePetMorphCodec()
	{
		return new JObjectCodec(() => new JObject
		{
			["Version"] = 1,
			["Enabled"] = false,
			["LiveBridgeEnabled"] = true,
			["Rules"] = new JArray()
		});
	}

	private static bool HasUtf8Bom(string path)
	{
		byte[] bytes = File.ReadAllBytes(path);
		return bytes.Length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf;
	}

	private static void WriteJson(string path, JObject value)
	{
		File.WriteAllText(
			path,
			JsonConvert.SerializeObject(value, Formatting.Indented),
			new UTF8Encoding(false));
	}

	private sealed class JObjectCodec : ISettingsSectionCodec<JObject>
	{
		private readonly Func<JObject> _defaultFactory;

		public JObjectCodec(Func<JObject> defaultFactory)
		{
			_defaultFactory = defaultFactory;
		}

		public JObject CreateDefault()
		{
			return (JObject)_defaultFactory().DeepClone();
		}

		public JObject DeserializeAndMigrate(JObject section)
		{
			return (JObject)section.DeepClone();
		}

		public JObject Normalize(JObject value)
		{
			return value == null ? CreateDefault() : (JObject)value.DeepClone();
		}

		public JObject Serialize(JObject value)
		{
			return (JObject)value.DeepClone();
		}
	}

	private sealed class FailingSettingsWriter : IAtomicSettingsWriter
	{
		public void WriteAllText(string path, string content)
		{
			throw new IOException("Simulated interrupted settings save.");
		}
	}

	private sealed class RejectingCodec : ISettingsSectionCodec<JObject>
	{
		public JObject CreateDefault()
		{
			return new JObject { ["Version"] = 1, ["SelectedThemeId"] = 0 };
		}

		public JObject DeserializeAndMigrate(JObject section)
		{
			throw new InvalidOperationException("Simulated module migration rejection.");
		}

		public JObject Normalize(JObject value)
		{
			return (JObject)value.DeepClone();
		}

		public JObject Serialize(JObject value)
		{
			return (JObject)value.DeepClone();
		}
	}
}
