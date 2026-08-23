using System;
using System.IO;

namespace AolaSocketHack.Verify;

/// <summary>
/// Source guard: AolaMainForm must not construct long-lived services or Cef
/// infrastructure; those belong to AolaCompositionRoot / BrowserHost.
/// </summary>
internal static class MainFormCompositionGuardVerifier
{
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
