using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.PetMorph.Coordination.Testing;
using AolaLoader.Features.PetMorph.Settings;
using AolaLoader.Settings;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class PetMorphCoordinatorVerifier
{
	public static bool Verify()
	{
		string root = Path.Combine(Path.GetTempPath(), "aola-petmorph-coordinator-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(root);
		try
		{
			return VerifyDefaults(root) &&
				VerifyRestoreFromSavedSettings(root) &&
				VerifyApplyAsyncSuccess(root) &&
				VerifyApplyAsyncSaveFailure(root) &&
				VerifyApplyAsyncBridgeUnavailable(root) &&
				VerifyApplyAsyncPushBlocked(root) &&
				VerifyApplyAsyncRuleRejected(root) &&
				VerifyPushCurrentRules(root);
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

	private static bool VerifyDefaults(string root)
	{
		string missingPath = Path.Combine(root, "missing.json");
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget();
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge();
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(missingPath),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		return !coordinator.Current.Enabled &&
			coordinator.Current.LiveBridgeEnabled &&
			coordinator.Current.Rules.Count == 0 &&
			coordinator.CurrentRules.Count == 0 &&
			!File.Exists(missingPath);
	}

	private static bool VerifyRestoreFromSavedSettings(string root)
	{
		string path = Path.Combine(root, "restore.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = true,
					["LiveBridgeEnabled"] = true,
					["Rules"] = new JArray
					{
						new JObject { ["Note"] = "restore", ["OriginalId"] = 5486, ["BackpackId"] = 5530 }
					}
				}
			}
		});
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget();
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			new ManualPetMorphPushBridge());
		coordinator.RestoreFromSavedSettings();
		return ruleTarget.SetRulesCallCount == 1 &&
			ruleTarget.LastEnabled &&
			ruleTarget.LastRules.Count == 1 &&
			ruleTarget.LastRules[0].OriginalId == 5486 &&
			ruleTarget.LastRules[0].BackpackId == 5530;
	}

	private static bool VerifyApplyAsyncSuccess(string root)
	{
		string path = Path.Combine(root, "apply-success.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = false,
					["LiveBridgeEnabled"] = true,
					["UnknownPetMorphField"] = "keep",
					["Rules"] = new JArray()
				}
			}
		});
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget(
			liveBridgeAvailable: true,
			posterMappings: new Dictionary<int, int> { { 5486, 5530 } });
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge(
			new AolaPetMorphPushResult(true, true, true, 1, null));
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		PetMorphApplyResult result = coordinator.ApplyAsync(
			new[]
			{
				new AolaPetMorphRule("morph", 5486, 5530, 0, 0, false, true, true)
			},
			true,
			CancellationToken.None).GetAwaiter().GetResult();
		if (!result.Succeeded || !result.BridgeAvailable || result.PushBlocked ||
			result.Push == null || !result.Push.Injected ||
			coordinator.Current.Enabled != true ||
			ruleTarget.SetRulesCallCount != 1 ||
			pushBridge.PushCallCount != 1)
		{
			return false;
		}

		ManualPetMorphPushBridge.PushCall call = pushBridge.Calls[0];
		if (!call.Enabled ||
			call.HiddenBackgrounds.Count != 1 || call.HiddenBackgrounds[5486] != true ||
			call.IconMappings.Count != 1 || call.IconMappings[5486] != 5530 ||
			call.SkinMappings.Count != 1 || call.SkinMappings[5486] != 5530)
		{
			return false;
		}

		JObject document = JObject.Parse(File.ReadAllText(path, Encoding.UTF8));
		JObject section = (JObject)document["Sections"]["petMorph"];
		return section.Value<bool>("Enabled") &&
			section.Value<bool>("LiveBridgeEnabled") &&
			section.Value<string>("UnknownPetMorphField") == "keep" &&
			((JArray)section["Rules"]).Count == 1 &&
			!HasUtf8Bom(path);
	}

	private static bool VerifyApplyAsyncSaveFailure(string root)
	{
		string path = Path.Combine(root, "apply-save-failure.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = false,
					["LiveBridgeEnabled"] = true,
					["Rules"] = new JArray()
				}
			}
		});
		byte[] before = File.ReadAllBytes(path);
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget();
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge();
		JsonSettingsSectionStore store = new JsonSettingsSectionStore(
			path,
			new FailingSettingsWriter(),
			new LegacySettingsMigrator());
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			store,
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		PetMorphApplyResult result = coordinator.ApplyAsync(
			new[] { new AolaPetMorphRule("x", 5486, 5530, 0, 0) },
			true,
			CancellationToken.None).GetAwaiter().GetResult();
		return result.RulesApplied && !result.SettingsSaved && !result.Succeeded &&
			!string.IsNullOrWhiteSpace(result.Error) &&
			ruleTarget.SetRulesCallCount == 1 &&
			pushBridge.PushCallCount == 0 &&
			coordinator.Current.Enabled == false &&
			before.SequenceEqual(File.ReadAllBytes(path));
	}

	private static bool VerifyApplyAsyncBridgeUnavailable(string root)
	{
		string path = Path.Combine(root, "apply-bridge-unavailable.json");
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget(liveBridgeAvailable: false);
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge();
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		PetMorphApplyResult result = coordinator.ApplyAsync(
			new[] { new AolaPetMorphRule("x", 5486, 5530, 0, 0) },
			true,
			CancellationToken.None).GetAwaiter().GetResult();
		return result.Succeeded && !result.BridgeAvailable &&
			pushBridge.PushCallCount == 0 &&
			coordinator.Current.Enabled &&
			File.Exists(path);
	}

	private static bool VerifyApplyAsyncPushBlocked(string root)
	{
		string path = Path.Combine(root, "apply-push-blocked.json");
		ThrowingRuleTarget ruleTarget = new ThrowingRuleTarget();
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge();
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		PetMorphApplyResult result = coordinator.ApplyAsync(
			new[] { new AolaPetMorphRule("x", 5486, 5530, 0, 0) },
			true,
			CancellationToken.None).GetAwaiter().GetResult();
		return result.Succeeded && result.BridgeAvailable && result.PushBlocked &&
			!string.IsNullOrWhiteSpace(result.Error) &&
			pushBridge.PushCallCount == 0;
	}

	private static bool VerifyApplyAsyncRuleRejected(string root)
	{
		string path = Path.Combine(root, "apply-rule-rejected.json");
		RejectingRuleTarget ruleTarget = new RejectingRuleTarget();
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge();
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		PetMorphApplyResult result = coordinator.ApplyAsync(
			new[] { new AolaPetMorphRule("x", 5486, 5530, 0, 0) },
			true,
			CancellationToken.None).GetAwaiter().GetResult();
		return !result.RulesApplied && !result.Succeeded &&
			!string.IsNullOrWhiteSpace(result.Error) &&
			pushBridge.PushCallCount == 0 &&
			!File.Exists(path);
	}

	private static bool VerifyPushCurrentRules(string root)
	{
		string path = Path.Combine(root, "push-current.json");
		WriteJson(path, new JObject
		{
			["DocumentVersion"] = 1,
			["Sections"] = new JObject
			{
				["petMorph"] = new JObject
				{
					["Version"] = 1,
					["Enabled"] = true,
					["LiveBridgeEnabled"] = true,
					["Rules"] = new JArray
					{
						new JObject
						{
							["Note"] = "current",
							["OriginalId"] = 5486,
							["BackpackId"] = 5530,
							["ReplaceBackpackIcon"] = true
						}
					}
				}
			}
		});
		byte[] before = File.ReadAllBytes(path);
		ManualPetMorphRuleTarget ruleTarget = new ManualPetMorphRuleTarget(
			posterMappings: new Dictionary<int, int> { { 5486, 5530 } });
		ManualPetMorphPushBridge pushBridge = new ManualPetMorphPushBridge(
			new AolaPetMorphPushResult(true, true, true, 2, null));
		PetMorphCoordinator coordinator = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			ruleTarget,
			pushBridge);
		AolaPetMorphPushResult push = coordinator.PushCurrentRulesAsync(
			CancellationToken.None).GetAwaiter().GetResult();
		if (push == null || !push.Injected || pushBridge.PushCallCount != 1 ||
			ruleTarget.SetRulesCallCount != 0 ||
			!before.SequenceEqual(File.ReadAllBytes(path)))
		{
			return false;
		}

		ManualPetMorphRuleTarget unavailable = new ManualPetMorphRuleTarget(liveBridgeAvailable: false);
		PetMorphCoordinator coordinator2 = new PetMorphCoordinator(
			new JsonSettingsSectionStore(path),
			new PetMorphSettingsCodec(),
			unavailable,
			new ManualPetMorphPushBridge());
		AolaPetMorphPushResult notInjected = coordinator2.PushCurrentRulesAsync(
			CancellationToken.None).GetAwaiter().GetResult();
		return notInjected != null && !notInjected.Injected && !string.IsNullOrWhiteSpace(notInjected.Error);
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

	private sealed class FailingSettingsWriter : IAtomicSettingsWriter
	{
		public void WriteAllText(string path, string content)
		{
			throw new IOException("Simulated interrupted PetMorph settings save.");
		}
	}

	private sealed class ThrowingRuleTarget : IPetMorphRuleTarget
	{
		public bool IsLiveBridgeAvailable => true;

		public void SetRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
		{
		}

		public string ValidateRule(AolaPetMorphRule rule)
		{
			return null;
		}

		public Task<IReadOnlyDictionary<int, int>> GetAvailableLivePosterMappingsAsync(
			IReadOnlyList<AolaPetMorphRule> rules,
			bool enabled)
		{
			throw new InvalidOperationException("Simulated mapping probe failure.");
		}
	}

	private sealed class RejectingRuleTarget : IPetMorphRuleTarget
	{
		public bool IsLiveBridgeAvailable => true;

		public void SetRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
		{
			throw new InvalidOperationException("Simulated rule rejection.");
		}

		public string ValidateRule(AolaPetMorphRule rule)
		{
			return null;
		}

		public Task<IReadOnlyDictionary<int, int>> GetAvailableLivePosterMappingsAsync(
			IReadOnlyList<AolaPetMorphRule> rules,
			bool enabled)
		{
			return Task.FromResult<IReadOnlyDictionary<int, int>>(new Dictionary<int, int>());
		}
	}
}
