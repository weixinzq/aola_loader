using System;
using System.IO;
using System.Text;

namespace AolaLoader.Settings;

internal interface IAtomicSettingsWriter
{
	void WriteAllText(string path, string content);
}

internal sealed class AtomicSettingsWriter : IAtomicSettingsWriter
{
	public void WriteAllText(string path, string content)
	{
		if (path == null)
		{
			throw new ArgumentNullException(nameof(path));
		}
		if (content == null)
		{
			throw new ArgumentNullException(nameof(content));
		}

		string fullPath = Path.GetFullPath(path);
		string directory = Path.GetDirectoryName(fullPath);
		if (string.IsNullOrWhiteSpace(directory))
		{
			throw new ArgumentException("Settings path must have a parent directory.", nameof(path));
		}

		Directory.CreateDirectory(directory);
		string temporaryPath = Path.Combine(
			directory,
			"." + Path.GetFileName(fullPath) + "." + Guid.NewGuid().ToString("N") + ".tmp");
		try
		{
			using (FileStream stream = new FileStream(
				temporaryPath,
				FileMode.CreateNew,
				FileAccess.Write,
				FileShare.None))
			using (StreamWriter writer = new StreamWriter(stream, new UTF8Encoding(false)))
			{
				writer.Write(content);
				writer.Flush();
				stream.Flush(true);
			}

			if (File.Exists(fullPath))
			{
				File.Replace(temporaryPath, fullPath, null);
			}
			else
			{
				File.Move(temporaryPath, fullPath);
			}
		}
		finally
		{
			try
			{
				if (File.Exists(temporaryPath))
				{
					File.Delete(temporaryPath);
				}
			}
			catch (IOException)
			{
			}
			catch (UnauthorizedAccessException)
			{
			}
		}
	}
}

