using System;
using System.IO;

namespace AolaSocketHack.Verify;

internal static class PacketHostSourceGuardVerifier
{
	private static readonly string[] ForbiddenStaticEvents =
	{
		"AolaHookHostService.PacketReceived",
		"AolaHookHostService.StatusReceived",
		"AolaHookHostService.SendCompleted"
	};

	public static bool Verify()
	{
		string repositoryRoot = FindRepositoryRoot();
		if (repositoryRoot == null)
		{
			Console.Error.WriteLine("PacketHost source guard could not locate the repository root.");
			return false;
		}

		string loaderRoot = Path.Combine(repositoryRoot, "analysis", "AolaLoader");
		string allowedAdapter = Path.GetFullPath(Path.Combine(
			loaderRoot,
			"PacketHost",
			"AolaHookHostAdapter.cs"));
		foreach (string path in Directory.GetFiles(loaderRoot, "*.cs", SearchOption.AllDirectories))
		{
			string fullPath = Path.GetFullPath(path);
			if (string.Equals(fullPath, allowedAdapter, StringComparison.OrdinalIgnoreCase))
			{
				continue;
			}
			string source = File.ReadAllText(fullPath);
			foreach (string forbidden in ForbiddenStaticEvents)
			{
				if (source.IndexOf(forbidden, StringComparison.Ordinal) >= 0)
				{
					Console.Error.WriteLine("PacketHost source guard rejected " + fullPath +
						" because it references " + forbidden + ".");
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
