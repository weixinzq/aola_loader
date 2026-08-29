using System;
using System.IO;

namespace AolaSocketHack.Verify;

internal static class PacketUiSourceGuardVerifier
{
	private static readonly string[] RequiredTokens =
	{
		"new CupertinoButton(\"抓包\"",
		"new CupertinoButton(\"发包\"",
		"new CupertinoButton(\"打开映射面板\"",
		"DataGridViewCheckBoxColumn",
		"packet.CanExport",
		"AolaSendExporter.TryCreateLine",
		"选中内容加入发包",
		"AppendCheckedToSend",
		"清空消息",
		"从文件导入",
		"_sendInput.AppendText"
	};

	private static readonly string[] RemovedTokens =
	{
		"Inner 明文详情",
		"RichTextBox _details",
		"FillFromSelected"
	};

	public static bool Verify()
	{
		string repositoryRoot = FindRepositoryRoot();
		if (repositoryRoot == null)
		{
			Console.Error.WriteLine("Packet UI source guard could not locate the repository root.");
			return false;
		}

		string path = Path.Combine(repositoryRoot, "analysis", "AolaLoader", "UI", "Packets", "AolaPacketsForm.cs");
		if (!File.Exists(path))
		{
			Console.Error.WriteLine("Packet UI source guard could not locate AolaPacketsForm.cs.");
			return false;
		}

		string source = File.ReadAllText(path);
		foreach (string token in RequiredTokens)
		{
			if (source.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Packet UI source guard is missing required token: " + token);
				return false;
			}
		}
		foreach (string token in RemovedTokens)
		{
			if (source.IndexOf(token, StringComparison.Ordinal) >= 0)
			{
				Console.Error.WriteLine("Packet UI source guard rejected removed token: " + token);
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
