using System;
using System.IO;

namespace AolaSocketHack.Verify;

internal static class CompatibilityPathSourceGuardVerifier
{
	private static readonly string[] RemovedTypeTokens =
	{
		"AolaAppSettings",
		"AolaSettingsStore",
		"AolaPetMorphRuleData",
		"AolaThemeRequestHandler"
	};

	public static bool Verify()
	{
		string repositoryRoot = FindRepositoryRoot();
		if (repositoryRoot == null)
		{
			Console.Error.WriteLine("Compatibility path source guard could not locate the repository root.");
			return false;
		}

		string loaderRoot = Path.Combine(repositoryRoot, "analysis", "AolaLoader");
		string compositionSource = File.ReadAllText(Path.Combine(
			loaderRoot, "AppShell", "AolaCompositionRoot.cs"));
		string normalizedCompositionSource = compositionSource.Replace("\r\n", "\n");
		string loaderProjectSource = File.ReadAllText(Path.Combine(loaderRoot, "AolaLoader.csproj"));
		if (normalizedCompositionSource.IndexOf(
			"Path.Combine(baseDirectory, \"Resources\", \"Patches\", \"start-bridge-2107300001.fws.swf\"),\n\t\t\tPath.Combine(baseDirectory, \"Resources\", \"Patches\", \"petfightnew-battle-state.current.json\"),",
			StringComparison.Ordinal) < 0 ||
			loaderProjectSource.IndexOf("petfightnew-battle-state-current.fws.swf", StringComparison.Ordinal) < 0 ||
			loaderProjectSource.IndexOf("petfightnew-battle-state.current.json", StringComparison.Ordinal) < 0 ||
			loaderProjectSource.IndexOf("petfightnew-battle-state-2026082731219998.fws.swf", StringComparison.Ordinal) >= 0 ||
			loaderProjectSource.IndexOf("petfightnew-battle-presentation-v2-2026082731219998.fws.swf", StringComparison.Ordinal) >= 0 ||
			loaderProjectSource.IndexOf("petfightnew-battle-2026082731219998.fws.swf", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard requires the stable battle-state manifest and rejects versioned or presentation production candidates.");
			return false;
		}
		string[] removedPaths =
		{
			Path.Combine(loaderRoot, "AolaSettings.cs"),
			Path.Combine(loaderRoot, "AolaDynamicRequestHandler.cs"),
			Path.Combine(loaderRoot, "ResourceInterception", "Cef", "AolaDynamicRequestHandler.cs")
		};
		foreach (string path in removedPaths)
		{
			if (File.Exists(path))
			{
				Console.Error.WriteLine("Compatibility path source guard rejected removed path " + path + ".");
				return false;
			}
		}

		string cefAdapterPath = Path.Combine(
			loaderRoot, "ResourceInterception", "Cef", "CefResourceRuleAdapter.cs");
		string cefAdapterSource = File.ReadAllText(cefAdapterPath);
		if (cefAdapterSource.IndexOf("handler.Headers[\"Cache-Control\"] = \"no-store, no-cache, must-revalidate\"", StringComparison.Ordinal) < 0 ||
			cefAdapterSource.IndexOf("handler.Headers[\"Pragma\"] = \"no-cache\"", StringComparison.Ordinal) < 0 ||
			cefAdapterSource.IndexOf("request.Flags =", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard requires no-store local responses without mutating CefSharp's read-only request.");
			return false;
		}

		string startBridgePath = Path.Combine(
			loaderRoot, "Resources", "Patches", "Sources", "start-2107300001",
			"mmo", "checkversion", "Load.as");
		string startBridgeSource = File.ReadAllText(startBridgePath);
		string[] requiredStartBridgeTokens =
		{
			"ExternalInterface.addCallback(\"aolaSendCommand\",this.onAolaSendCommand)",
			"ExternalInterface.addCallback(\"aolaOpenPanel\",this.onAolaOpenPanel)",
			"ExternalInterface.addCallback(\"aolaSetPlayback\",this.onAolaSetPlayback)",
			"ExternalInterface.addCallback(\"aolaTrimMemory\",this.onAolaTrimMemory)",
			"ExternalInterface.addCallback(\"aolaGetRuntimeStats\",this.onAolaGetRuntimeStats)",
			"System.pauseForGCIfCollectionImminent(0.25)",
			"\"TrimApplied|\"",
			"\"RuntimeStats|\"",
			"ApplicationDomain.currentDomain.hasDefinition(ACT_CLIENT_SENDER)",
			"ApplicationDomain.currentDomain.getDefinition(ACT_CLIENT_SENDER)",
			"sender[\"sendMessage\"](extension,command,parameters",
			"private static const MAX_PENDING_COMMANDS:int = 256",
			"new LoaderContext(false,ApplicationDomain.currentDomain)",
			"param2.hasOwnProperty(\"r\")",
			"param2.hasOwnProperty(\"suc\")",
			"param2.hasOwnProperty(\"res\")",
			"code == 1 ? \"ServerSucceeded\" : \"ServerRejected\"",
			"return \"BridgeNotReady\"",
			"return \"SubmittedToFlash\""
		};
		foreach (string token in requiredStartBridgeTokens)
		{
			if (startBridgeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires start.swf bridge token " + token + ".");
				return false;
			}
		}
		if (startBridgeSource.IndexOf("import mmo.play.actthings.data.ActClientSender", StringComparison.Ordinal) >= 0 ||
			startBridgeSource.IndexOf("import mmo.play.activity.helper.Panel_Helper", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard rejected hard imports from the startup bridge.");
			return false;
		}
		if (startBridgeSource.IndexOf("System.gc(", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard rejected forced GC from the startup bridge.");
			return false;
		}

		string pageBridgePath = Path.Combine(loaderRoot, "BrowserHost", "AolaPageBridge.cs");
		string pageBridgeSource = File.ReadAllText(pageBridgePath);
		string[] requiredRuntimePageTokens =
		{
			"operation === 'system.trimMemory'",
			"operation === 'system.runtimeStats'",
			"aolaTrimMemory(trimLevel)",
			"aolaGetRuntimeStats()",
			"trimParts[0] !== 'TrimApplied'",
			"statsParts[0] !== 'RuntimeStats'"
		};
		foreach (string token in requiredRuntimePageTokens)
		{
			if (pageBridgeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires page bridge token " + token + ".");
				return false;
			}
		}

		string flashRuntimeClientPath = Path.Combine(
			loaderRoot, "Features", "Runtime", "FlashRuntimeClient.cs");
		string flashRuntimeClientSource = File.ReadAllText(flashRuntimeClientPath);
		string[] requiredFlashRuntimeTokens =
		{
			"\"system.trimMemory\"",
			"\"system.runtimeStats\"",
			"TrimMemoryAsync",
			"GetRuntimeStatsAsync"
		};
		foreach (string token in requiredFlashRuntimeTokens)
		{
			if (flashRuntimeClientSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires flash runtime client token " + token + ".");
				return false;
			}
		}

		string mainFormRuntimePath = Path.Combine(loaderRoot, "AppShell", "AolaMainForm.cs");
		string mainFormRuntimeSource = File.ReadAllText(mainFormRuntimePath);
		string[] requiredRuntimeTriggerTokens =
		{
			"AOLA_TRIM_MEMORY",
			"runtime-memory.jsonl",
			"TimeSpan.FromSeconds(5)",
			"TimeSpan.FromSeconds(1)",
			"TimeSpan.FromMinutes(5)",
			"TimeSpan.FromMinutes(10)",
			"RuntimeLongFrameFuseMs = 500"
		};
		foreach (string token in requiredRuntimeTriggerTokens)
		{
			if (mainFormRuntimeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires runtime trigger token " + token + ".");
				return false;
			}
		}

		string[] requiredOwnerProbePageTokens =
		{
			"operation === 'battle.probeRelease'",
			"aolaBattleProbeRelease",
			"aolaBattleProbeRelease(probeMode)",
			"validProbeSnapshot(probe.before)",
			"validProbeActions(probe.actions)"
		};
		foreach (string token in requiredOwnerProbePageTokens)
		{
			if (pageBridgeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires owner probe page token " + token + ".");
				return false;
			}
		}
		string[] requiredOwnerProbeTriggerTokens =
		{
			"AOLA_BATTLE_PROBE",
			"AOLA_BATTLE_PROBE_MODE",
			"battle-owner-probe.jsonl",
			"AOLA_TRIM_MEMORY",
			"_trimMemoryMode == 0",
			"ParseTrimMemoryMode",
			"BattleOwnerProbeAfterBattle"
		};
		foreach (string token in requiredOwnerProbeTriggerTokens)
		{
			if (mainFormRuntimeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires owner probe trigger token " + token + ".");
				return false;
			}
		}

		string updateStartBridgePath = Path.Combine(
			repositoryRoot, "analysis", "tools", "Update-StartBridge.ps1");
		string updateStartBridgeSource = File.ReadAllText(updateStartBridgePath);
		string[] requiredStartBridgeUpdateTokens =
		{
			"D:\\Programs\\FFdec\\ffdec-cli.exe",
			"mmo.checkversion.Load",
			"start-bridge-2107300001.fws.swf",
			"aolaTrimMemory",
			"aolaGetRuntimeStats",
			"pauseForGCIfCollectionImminent(0.25)"
		};
		foreach (string token in requiredStartBridgeUpdateTokens)
		{
			if (updateStartBridgeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires start bridge update token " + token + ".");
				return false;
			}
		}

		string petDocClassPath = Path.Combine(
			loaderRoot, "Resources", "Patches", "Sources", "newpetpackage-2026082731219998",
			"mmo", "petpackage", "DocClass.as");
		string petDocClassSource = File.ReadAllText(petDocClassPath);
		if (petDocClassSource.IndexOf("aolaSendCommand", StringComparison.Ordinal) >= 0 ||
			petDocClassSource.IndexOf("aolaOpenPanel", StringComparison.Ordinal) >= 0 ||
			petDocClassSource.IndexOf("aolaSetPlayback", StringComparison.Ordinal) >= 0 ||
			petDocClassSource.IndexOf("ensureAolaCommandBridge", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard requires a morph-only newpetpackage DocClass.");
			return false;
		}
		string[] morphSourcePaths =
		{
			Path.Combine(loaderRoot, "Resources", "Patches", "Sources", "newpetpackage-2026082731219998",
				"mmo", "petpackage", "panel", "SimpleViewController.as"),
			Path.Combine(loaderRoot, "Resources", "Patches", "Sources", "newpetpackage-2026082731219998",
				"mmo", "petpackage", "panel", "inclusion", "PetBigIconDetail.as")
		};
		foreach (string morphSourcePath in morphSourcePaths)
		{
			string morphSource = File.ReadAllText(morphSourcePath);
			if (morphSource.IndexOf("aolaMorph", StringComparison.Ordinal) < 0 ||
				morphSource.IndexOf("ensureAolaCommandBridge", StringComparison.Ordinal) >= 0 ||
				morphSource.IndexOf("import mmo.petpackage.DocClass", StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires morph-only backpack sources.");
				return false;
			}
		}

		string battleBridgePath = Path.Combine(
			repositoryRoot, "analysis", "tools", "petfight", "DocPetFight.bridge.template.as");
		string battleBridgeSource = File.ReadAllText(battleBridgePath);
		string[] requiredBattleTokens =
		{
			"private static const BRIDGE_VERSION:int = 5",
			"public static var skipBattlePresentation:Boolean = false",
			"ExternalInterface.addCallback(\"aolaBattleApplyOptions\",onAolaBattleApplyOptions)",
			"ExternalInterface.addCallback(\"aolaBattleGetDiagnostics\",onAolaBattleGetDiagnostics)",
			"ExternalInterface.addCallback(\"aolaBattleDrainTraceEvents\",onAolaBattleDrainTraceEvents)",
			"new Dictionary(true)",
			"new Array(MAX_TRACE_EVENTS)",
			"_diagnosticTraceHead",
			"noteDiagnosticPanelDisposeStarted",
			"LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,onDiagnosticFrame,false,0,true)",
			"\"version\":DIAGNOSTICS_VERSION",
			"int(options.version) != options.version",
			"typeof options.skipBattlePresentation != \"boolean\""
		};
		foreach (string token in requiredBattleTokens)
		{
			if (battleBridgeSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires battle bridge token " + token + ".");
				return false;
			}
		}
		string[] forbiddenBattleTokens =
		{
			"fightSkillEffect",
			"NoFightSkillEffect",
			"AllFightSkillEffect",
			"IGameOptionService",
			"skipPetAttackActions",
			"skipBattleVisualDelays",
			"skipAttackAnimation",
			"System.gc(",
			"DomainLoader.unloadRes",
			"ResScheduler.cancel"
		};
		foreach (string token in forbiddenBattleTokens)
		{
			if (battleBridgeSource.IndexOf(token, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("Compatibility path source guard rejected battle bridge token " + token + ".");
				return false;
			}
		}

		string updateScriptPath = Path.Combine(
			repositoryRoot, "analysis", "tools", "Update-PetFightBattleBridge.ps1");
		string updateScriptSource = File.ReadAllText(updateScriptPath);
		string[] requiredUpdateTokens =
		{
			"[ValidateSet('Check', 'Prepare', 'Promote')]",
			"start.xml",
			"pet/petfightnew",
			"PetFightService:init",
			"FightPanel:enableClick",
			"StartMovie:$iinit",
			"PreLoadAssetsUtil:onLoadCompleted",
			"ResourceCleanupMode",
			"Apply-ConservativePreloadCompletion",
			"Assert-PcodeTrees",
			"Promote requires -CandidateManifest with an explicit path."
		};
		foreach (string token in requiredUpdateTokens)
		{
			if (updateScriptSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires weekly update token " + token + ".");
				return false;
			}
		}
		string presentationBuilderPath = Path.Combine(
			repositoryRoot, "analysis", "tools", "petfight", "New-PetFightPresentationPatches.ps1");
		string presentationBuilderSource = File.ReadAllText(presentationBuilderPath);
		string[] requiredPresentationTokens =
		{
			"UseSkill:handleUseSkill",
			"UseSkill:handleAnnalFeeEight",
			"UseSkill:handleMovie",
			"UseSkill:getMuiltHitDecHpDelayFrame",
			"FightController:startHandle",
			"SwitchPm:showSwitchMc",
			"ChangePetView:onGotPet",
			"ChangePetView:onPetChange",
			"BattlePmDying:showPetDieEffect",
			"BattleNextTurn:checkPlayMovie",
			"SkillResultMovieHandler:showMultipleHit",
			"hideHealingNumbers",
			"hideDamageNumbers",
			"setBackGroundUp",
			"handleSkillEnd"
		};
		foreach (string token in requiredPresentationTokens)
		{
			if (presentationBuilderSource.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Compatibility path source guard requires presentation patch token " + token + ".");
				return false;
			}
		}
		foreach (string token in new[] { "fightSkillEffect", "FightData.isLowQuality", "startMovie('" })
		{
			if (presentationBuilderSource.IndexOf(token, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("Compatibility path source guard rejected presentation patch token " + token + ".");
				return false;
			}
		}

		foreach (string path in Directory.GetFiles(loaderRoot, "*.cs", SearchOption.AllDirectories))
		{
			string source = File.ReadAllText(path);
			foreach (string token in RemovedTypeTokens)
			{
				if (source.IndexOf(token, StringComparison.Ordinal) >= 0)
				{
					Console.Error.WriteLine("Compatibility path source guard rejected " + path +
						" because it references removed type " + token + ".");
					return false;
				}
			}
		}
		return true;
	}

	private static string FindRepositoryRoot()
	{
		string[] seeds = { Environment.CurrentDirectory, AppContext.BaseDirectory };
		foreach (string seed in seeds)
		{
			DirectoryInfo directory = new DirectoryInfo(seed);
			while (directory != null)
			{
				if (Directory.Exists(Path.Combine(directory.FullName, "analysis", "AolaLoader")))
				{
					return directory.FullName;
				}
				directory = directory.Parent;
			}
		}
		return null;
	}
}
