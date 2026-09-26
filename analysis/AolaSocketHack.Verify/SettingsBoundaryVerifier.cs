using System;
using System.IO;
using System.Linq;
using System.Text;
using AolaLoader.Features.Battle.Settings;
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
			return Check("missing-roundtrip", VerifyMissingAndRoundTrip(root)) &&
				Check("typed-theme", VerifyTypedThemeSettingsAndLegacyMigration(root)) &&
				Check("typed-petmorph", VerifyTypedPetMorphSettings(root)) &&
				Check("typed-battle", VerifyTypedBattleSettings(root)) &&
				Check("production-migration", VerifyProductionThemeAndPetMorphMigration(root)) &&
				Check("unknown-content", VerifyUnknownContentAndIndependentUpdates(root)) &&
				Check("corrupt-isolation", VerifyCorruptSectionIsolation(root)) &&
				Check("legacy-migration", VerifyLegacyMigration(root)) &&
				Check("migration-failure", VerifyMigrationFailurePreservesEvidence(root)) &&
				Check("codec-failure", VerifyCodecMigrationFailurePreservesEvidence(root)) &&
				Check("interrupted-save", VerifyInterruptedSavePreservesFile(root));
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

	private static bool Check(string name, bool passed)
	{
		if (!passed) Console.Error.WriteLine("Settings verifier stage failed: " + name);
		return passed;
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

	private static bool VerifyTypedBattleSettings(string root)
	{
		BattleSettingsCodec codec = new BattleSettingsCodec();
		ThemeSettingsCodec themeCodec = new ThemeSettingsCodec();

		// 无文件时返回禁用默认值。
		string missingPath = Path.Combine(root, "typed-battle-missing.json");
		SettingsSectionLoadResult<BattleSettings> missing =
			new JsonSettingsSectionStore(missingPath).Load(BattleSettingsCodec.SectionKey, codec);
		if (!missing.UsedDefault || missing.Error != null || !IsDefaultBattle(missing.Value))
		{
			Console.Error.WriteLine("typed-battle: missing-default");
			return false;
		}
		BattleSettings migratedV1 = codec.DeserializeAndMigrate(new JObject
		{
			["Version"] = 1,
			["SkipPetAttackActions"] = true
		});
		BattleSettings migratedV2 = codec.DeserializeAndMigrate(new JObject
		{
			["Version"] = 2,
			["SkipPetAttackActions"] = true
		});
		BattleSettings migratedV3 = codec.DeserializeAndMigrate(new JObject
		{
			["Version"] = 3,
			["SkipBattlePresentation"] = true
		});
		BattleSettings migratedV4 = codec.DeserializeAndMigrate(new JObject
		{
			["Version"] = 4,
			["SkipAttackAnimation"] = true
		});
		if (!migratedV1.SkipBattlePresentation || !migratedV2.SkipBattlePresentation ||
			!migratedV3.SkipBattlePresentation || !migratedV4.SkipBattlePresentation)
		{
			Console.Error.WriteLine("typed-battle: visual-migration");
			return false;
		}
		foreach (bool hideDamage in new[] { false, true })
		{
			foreach (bool hideHealing in new[] { false, true })
			{
				BattleSettings combination = codec.DeserializeAndMigrate(codec.Serialize(
					new BattleSettings(hideDamage, hideHealing, true, false, Array.Empty<BattleMorphRule>())));
				if (combination.HideDamageNumbers != hideDamage ||
					combination.HideHealingNumbers != hideHealing ||
					!combination.SkipBattlePresentation)
				{
					Console.Error.WriteLine("typed-battle: number-combination");
					return false;
				}
			}
		}

		// 旧版仅迁移可识别的强类型规则；未知规则禁用并报告；保存后无 BOM。
		string path = Path.Combine(root, "typed-battle.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = new JObject
				{
					["Version"] = 1,
					["UnknownBattleField"] = "keep-battle",
					["MorphRules"] = new JArray
					{
						new JObject { ["FutureRuleField"] = 91 }
					}
				}
			}
		});
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(path);
		SettingsSectionLoadResult<BattleSettings> loaded =
			store.Load(BattleSettingsCodec.SectionKey, codec);
		if (loaded.UsedDefault || loaded.Value.HideDamageNumbers || loaded.Value.HideHealingNumbers ||
			loaded.Value.SkipBattlePresentation ||
			loaded.Value.BattleMorphEnabled || loaded.Value.MorphRules.Count != 0 ||
			loaded.Value.IgnoredLegacyMorphRuleCount != 1)
		{
			Console.Error.WriteLine("typed-battle: v1-load");
			return false;
		}
		if (!store.Save(
			BattleSettingsCodec.SectionKey,
			new BattleSettings(true, false, true, true, new[]
			{
				new BattleMorphRule("测试", 6000, 6047),
				new BattleMorphRule("第二条", 6001, 6057)
			}),
			codec).Succeeded)
		{
			Console.Error.WriteLine("typed-battle: save");
			return false;
		}
		JObject saved = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject section = (JObject)saved["Sections"]["battle"];
		JObject savedRule = (JObject)((JArray)section["MorphRules"])[0];
		if (section.Value<string>("UnknownBattleField") != "keep-battle" ||
			savedRule.Value<string>("Note") != "测试" ||
			savedRule.Value<int>("SourceViewId") != 6000 || savedRule.Value<int>("TargetViewId") != 6047 ||
			!section.Value<bool>("HideDamageNumbers") || section.Value<bool>("HideHealingNumbers") ||
			!section.Value<bool>("SkipBattlePresentation") || !section.Value<bool>("BattleMorphEnabled") ||
			section.Value<int>("Version") != 6 ||
			section["SkipAttackAnimation"] != null ||
			section["SkipPetAttackActions"] != null || section["SkipBattleVisualDelays"] != null ||
			section["FightSkillEffect"] != null ||
			HasUtf8Bom(path))
		{
			Console.Error.WriteLine("typed-battle: saved-shape " + section.ToString(Formatting.None));
			return false;
		}
		SettingsSectionLoadResult<BattleSettings> roundTrip =
			store.Load(BattleSettingsCodec.SectionKey, codec);
		if (roundTrip.UsedDefault || !roundTrip.Value.HideDamageNumbers ||
			roundTrip.Value.HideHealingNumbers || !roundTrip.Value.SkipBattlePresentation ||
			!roundTrip.Value.BattleMorphEnabled || roundTrip.Value.MorphRules.Count != 2 ||
			roundTrip.Value.MorphRules[0].SourceViewId != 6000 ||
			roundTrip.Value.MorphRules[0].TargetViewId != 6047 ||
			roundTrip.Value.MorphRules[1].Note != "第二条" ||
			roundTrip.Value.MorphRules[1].SourceViewId != 6001 ||
			roundTrip.Value.MorphRules[1].TargetViewId != 6057)
		{
			Console.Error.WriteLine("typed-battle: roundtrip");
			return false;
		}
		if (!store.Save(BattleSettingsCodec.SectionKey,
			new BattleSettings(true, false, true, true, roundTrip.Value.MorphRules.Skip(1)), codec).Succeeded)
		{
			return false;
		}
		BattleSettings afterDelete = new JsonSettingsSectionStore(path)
			.Load(BattleSettingsCodec.SectionKey, codec).Value;
		if (afterDelete.MorphRules.Count != 1 || afterDelete.MorphRules[0].SourceViewId != 6001 ||
			afterDelete.MorphRules[0].TargetViewId != 6057 || afterDelete.MorphRules[0].Note != "第二条")
		{
			Console.Error.WriteLine("typed-battle: delete-roundtrip");
			return false;
		}
		// 不支持版本时回退默认并保留原文件。
		string versionPath = Path.Combine(root, "typed-battle-version.json");
		WriteJson(versionPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = new JObject { ["Version"] = 7 }
			}
		});
		byte[] versionBefore = File.ReadAllBytes(versionPath);
		SettingsSectionLoadResult<BattleSettings> unsupported =
			new JsonSettingsSectionStore(versionPath).Load(BattleSettingsCodec.SectionKey, codec);
		if (!unsupported.UsedDefault || string.IsNullOrWhiteSpace(unsupported.Error) ||
			!IsDefaultBattle(unsupported.Value) ||
			!versionBefore.SequenceEqual(File.ReadAllBytes(versionPath)))
		{
			Console.Error.WriteLine("typed-battle: unsupported-version");
			return false;
		}

		// 错误类型字段时回退默认并保留原文件。
		string invalidPath = Path.Combine(root, "typed-battle-invalid.json");
		WriteJson(invalidPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = new JObject
				{
					["Version"] = 6,
					["SkipBattlePresentation"] = "invalid",
					["MorphRules"] = new JArray()
				}
			}
		});
		byte[] invalidBefore = File.ReadAllBytes(invalidPath);
		SettingsSectionLoadResult<BattleSettings> invalid =
			new JsonSettingsSectionStore(invalidPath).Load(BattleSettingsCodec.SectionKey, codec);
		if (!invalid.UsedDefault || string.IsNullOrWhiteSpace(invalid.Error) ||
			!IsDefaultBattle(invalid.Value) || !invalidBefore.SequenceEqual(File.ReadAllBytes(invalidPath)))
		{
			Console.Error.WriteLine("typed-battle: invalid-field");
			return false;
		}

		// MorphRules 非数组时拒绝并回退。
		string rulesPath = Path.Combine(root, "typed-battle-rules.json");
		WriteJson(rulesPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = new JObject
				{
					["Version"] = 1,
					["MorphRules"] = "invalid"
				}
			}
		});
		byte[] rulesBefore = File.ReadAllBytes(rulesPath);
		SettingsSectionLoadResult<BattleSettings> badRules =
			new JsonSettingsSectionStore(rulesPath).Load(BattleSettingsCodec.SectionKey, codec);
		if (!badRules.UsedDefault || string.IsNullOrWhiteSpace(badRules.Error) ||
			!rulesBefore.SequenceEqual(File.ReadAllBytes(rulesPath)))
		{
			Console.Error.WriteLine("typed-battle: invalid-rules");
			return false;
		}

		// 旧 SchemaVersion 5 迁移时建立 Battle Version 6 默认 Section。
		string legacyPath = Path.Combine(root, "typed-battle-legacy.json");
		WriteJson(legacyPath, new JObject
		{
			["SchemaVersion"] = 5,
			["SelectedThemeId"] = 1,
			["PetMorphEnabled"] = false,
			["PetMorphLiveBridgeEnabled"] = true,
			["PetMorphRules"] = new JArray()
		});
		JsonSettingsSectionStore legacyStore = new JsonSettingsSectionStore(legacyPath);
		SettingsSectionLoadResult<BattleSettings> migrated =
			legacyStore.Load(BattleSettingsCodec.SectionKey, codec);
		if (migrated.UsedDefault || !migrated.LegacyDocumentMigrated ||
			!IsDefaultBattle(migrated.Value) || HasUtf8Bom(legacyPath))
		{
			Console.Error.WriteLine("typed-battle: legacy-load");
			return false;
		}
		JObject migratedDoc = JObject.Parse(File.ReadAllText(legacyPath, Encoding.UTF8));
		JObject battle = (JObject)migratedDoc["Sections"]["battle"];
		if (battle.Value<int>("Version") != 6 ||
			battle.Value<bool>("HideDamageNumbers") || battle.Value<bool>("HideHealingNumbers") ||
			!battle.Value<bool>("SkipBattlePresentation") || battle.Value<bool>("BattleMorphEnabled") ||
			battle["SkipAttackAnimation"] != null ||
			battle["SkipPetAttackActions"] != null || battle["FightSkillEffect"] != null ||
			((JArray)battle["MorphRules"]).Count != 0)
		{
			Console.Error.WriteLine("typed-battle: legacy-shape " + battle.ToString(Formatting.None));
			return false;
		}

		// Theme、PetMorph、Battle 任意顺序独立保存互不覆盖，未知 Section 保留。
		string orderPath = Path.Combine(root, "typed-battle-order.json");
		WriteJson(orderPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["theme"] = new JObject
				{
					["Version"] = 1,
					["SelectedThemeId"] = 2,
					["UnknownThemeField"] = "keep-theme"
				},
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = true,
					["LiveBridgeEnabled"] = false,
					["Rules"] = new JArray()
				},
				["futureModule"] = new JObject { ["Version"] = 7, ["Value"] = 99 }
			}
		});
		JsonSettingsSectionStore orderStore = new JsonSettingsSectionStore(orderPath);
		PetMorphSettingsCodec petMorphCodec = new PetMorphSettingsCodec();
		if (!orderStore.Save(
			BattleSettingsCodec.SectionKey,
			new BattleSettings(true, true, true, false, Array.Empty<BattleMorphRule>()),
			codec).Succeeded ||
			!orderStore.Save(ThemeSettingsCodec.SectionKey, new ThemeSettings(6), themeCodec).Succeeded ||
			!orderStore.Save(
				PetMorphSettingsCodec.SectionKey,
				new PetMorphSettings(false, true, Array.Empty<PetMorphRuleSettings>()),
				petMorphCodec).Succeeded ||
			!orderStore.Save(
				BattleSettingsCodec.SectionKey,
				new BattleSettings(false, false, false, false, Array.Empty<BattleMorphRule>()),
				codec).Succeeded)
		{
			Console.Error.WriteLine("typed-battle: independent-save");
			return false;
		}
		JObject ordered = JObject.Parse(File.ReadAllText(orderPath, Encoding.UTF8));
		JObject orderedSections = (JObject)ordered["Sections"];
		JObject orderedBattle = (JObject)orderedSections["battle"];
		if (orderedSections["theme"].Value<int>("SelectedThemeId") != 6 ||
			orderedSections["theme"].Value<string>("UnknownThemeField") != "keep-theme" ||
			orderedSections["petMorph"].Value<bool>("Enabled") ||
			!orderedSections["petMorph"].Value<bool>("LiveBridgeEnabled") ||
			orderedSections["futureModule"].Value<int>("Value") != 99 ||
			orderedBattle.Value<bool>("HideDamageNumbers") ||
			orderedBattle.Value<bool>("HideHealingNumbers") ||
			orderedBattle.Value<bool>("SkipBattlePresentation") ||
			orderedBattle.Value<bool>("BattleMorphEnabled") ||
			orderedBattle["SkipAttackAnimation"] != null ||
			orderedBattle["SkipPetAttackActions"] != null ||
			orderedBattle["SkipBattleVisualDelays"] != null ||
			orderedBattle["FightSkillEffect"] != null ||
			HasUtf8Bom(orderPath))
		{
			Console.Error.WriteLine("typed-battle: independent-shape " + orderedBattle.ToString(Formatting.None));
			return false;
		}

		// 损坏的 battle Section 回退默认且不影响其他 Section。
		string corruptPath = Path.Combine(root, "typed-battle-corrupt.json");
		WriteJson(corruptPath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = "not-an-object",
				["theme"] = new JObject { ["Version"] = 1, ["SelectedThemeId"] = 3 }
			}
		});
		JsonSettingsSectionStore corruptStore = new JsonSettingsSectionStore(corruptPath);
		SettingsSectionLoadResult<BattleSettings> corruptBattle =
			corruptStore.Load(BattleSettingsCodec.SectionKey, codec);
		SettingsSectionLoadResult<ThemeSettings> intactTheme =
			corruptStore.Load(ThemeSettingsCodec.SectionKey, themeCodec);
		if (!corruptBattle.UsedDefault || string.IsNullOrWhiteSpace(corruptBattle.Error) ||
			!IsDefaultBattle(corruptBattle.Value) ||
			intactTheme.UsedDefault || intactTheme.Value.SelectedThemeId != 3)
		{
			Console.Error.WriteLine("typed-battle: corrupt-isolation");
			return false;
		}

		// 保存失败不破坏旧文件。
		string failurePath = Path.Combine(root, "typed-battle-failure.json");
		WriteJson(failurePath, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["battle"] = new JObject { ["Version"] = 1, ["FightSkillEffect"] = 1 }
			}
		});
		byte[] failureBefore = File.ReadAllBytes(failurePath);
		SettingsSectionSaveResult failed = new JsonSettingsSectionStore(
			failurePath,
			new FailingSettingsWriter(),
			new LegacySettingsMigrator()).Save(
			BattleSettingsCodec.SectionKey,
			new BattleSettings(false, false, false, false, Array.Empty<BattleMorphRule>()),
			codec);
		bool failurePreserved = !failed.Succeeded && !string.IsNullOrWhiteSpace(failed.Error) &&
			failureBefore.SequenceEqual(File.ReadAllBytes(failurePath));
		if (!failurePreserved) Console.Error.WriteLine("typed-battle: save-failure");
		return failurePreserved;
	}

	private static bool IsDefaultBattle(BattleSettings value)
	{
		return value != null &&
			!value.HideDamageNumbers &&
			!value.HideHealingNumbers &&
			value.SkipBattlePresentation &&
			!value.BattleMorphEnabled &&
			value.MorphRules != null &&
			value.MorphRules.Count == 0;
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
