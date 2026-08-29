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

		string petBridgePath = Path.Combine(
			loaderRoot, "Resources", "Patches", "Sources", "newpetpackage-2026082731219998",
			"mmo", "petpackage", "DocClass.as");
		string petBridgeSource = File.ReadAllText(petBridgePath);
		int commandBridgeIndex = petBridgeSource.IndexOf(
			"public static function ensureAolaCommandBridge()", StringComparison.Ordinal);
		int playbackCallbackIndex = petBridgeSource.IndexOf(
			"ExternalInterface.addCallback(\"aolaSetPlayback\",onAolaSetPlayback)", StringComparison.Ordinal);
		if (commandBridgeIndex < 0 || playbackCallbackIndex < commandBridgeIndex ||
			petBridgeSource.IndexOf("private static function onAolaSetPlayback", StringComparison.Ordinal) < 0 ||
			petBridgeSource.IndexOf("LoaderContainer.instance.stage", StringComparison.Ordinal) < 0 ||
			petBridgeSource.IndexOf("ensureAolaPlaybackBridge", StringComparison.Ordinal) >= 0)
		{
			Console.Error.WriteLine("Compatibility path source guard requires playback registration through the proven static backpack bridge entry.");
			return false;
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
