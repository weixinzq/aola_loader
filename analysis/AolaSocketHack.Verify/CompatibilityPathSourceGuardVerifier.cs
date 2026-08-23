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
