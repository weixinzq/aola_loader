using System;
using System.IO;

namespace AolaSocketHack.Verify;

/// <summary>
/// Source guard: AolaMainForm must not construct long-lived services or Cef
/// infrastructure; those belong to AolaCompositionRoot / BrowserHost.
/// </summary>
internal static class MainFormCompositionGuardVerifier
{
	private static readonly string[] RequiredResponsivenessTokens =
	{
		"EnsureHookInjectedAsync",
		"await Task.Run(FindNetworkProcessId)",
		"await Task.Run(() => _hookController.EnsureInjected",
		"FormBorderStyle = FormBorderStyle.FixedSingle",
		"MaximizeBox = false",
		"Size = new Size(1220, 800)",
		"ToolStripDropDownButton extensions = BuildExtensionsButton()",
		"extensions, refresh, packets, _playbackMenu, _qualityMenu, devTools, retainLog",
		"Refresh(BrowserRefreshMode.IgnoreCache)",
		"\"playback.apply\""
	};

	private static readonly string[] ForbiddenToolbarTokens =
	{
		"ToolStripTextBox _address",
		"ToolStripButton(\"后退\")",
		"ToolStripButton(\"前进\")",
		"ToolStripButton(\"打开\")",
		"MenuStrip menuStrip = BuildMenu()",
		"Refresh(BrowserRefreshMode.Normal)"
	};

	private static readonly string[] ForbiddenConstructionTokens =
	{
		"new AolaHookController(",
		"new AolaHookHostAdapter(",
		"new AolaReceiveLogger(",
		"new AolaBattleStateTracker(",
		"new AolaResourceRequestHandler(",
		"new ThemeCoordinator(",
		"new PetMorphCoordinator(",
		"new ChildWindowCoordinator(",
		"new AolaBrowserSession(",
		"new ChromiumWebBrowser(",
		"new JsonSettingsSectionStore(",
		"new AolaBrowserPetMorphPushBridge(",
		"new AolaPetMorphLiveBridge(",
		"Cef.Initialize(",
		"InitializeCef("
	};

	private static readonly string[] ForbiddenTypeReferences =
	{
		"AolaProtocol",
		"AolaBattlePacketParser",
		"AolaSwf",
		"AolaPetPosterCatalog",
		"AolaHookHostService",
		"AolaCapture",
		"JsonSettingsSectionStore",
		"LegacySettingsMigrator",
		"EasyHook"
	};

	public static bool Verify()
	{
		string repositoryRoot = FindRepositoryRoot();
		if (repositoryRoot == null)
		{
			Console.Error.WriteLine("MainForm composition guard could not locate the repository root.");
			return false;
		}

		string mainFormPath = Path.Combine(
			repositoryRoot,
			"analysis",
			"AolaLoader",
			"AppShell",
			"AolaMainForm.cs");
		if (!File.Exists(mainFormPath))
		{
			Console.Error.WriteLine("MainForm composition guard could not find AolaMainForm.cs.");
			return false;
		}
		string source = File.ReadAllText(mainFormPath);
		foreach (string required in RequiredResponsivenessTokens)
		{
			if (source.IndexOf(required, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("MainForm responsiveness guard is missing " + required + ".");
				return false;
			}
		}
		if (source.IndexOf("Tick += delegate { EnsureHookInjected(); }", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("MainForm responsiveness guard rejected synchronous hook polling on the UI timer.");
			return false;
		}
		foreach (string forbidden in ForbiddenToolbarTokens)
		{
			if (source.IndexOf(forbidden, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("MainForm toolbar guard rejected " + forbidden + ".");
				return false;
			}
		}
		foreach (string forbidden in ForbiddenConstructionTokens)
		{
			if (source.IndexOf(forbidden, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("MainForm composition guard rejected " + mainFormPath +
					" because it constructs " + forbidden + ".");
				return false;
			}
		}
		foreach (string forbidden in ForbiddenTypeReferences)
		{
			if (source.IndexOf(forbidden, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("MainForm composition guard rejected " + mainFormPath +
					" because it references " + forbidden + ".");
				return false;
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
