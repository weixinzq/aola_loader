// 架构角色：拥有主题叶子 SWF 请求，在选定主题时返回对应本地模板资源。
// 数据流：资源 URL + 当前 themeId -> LocalResponse 或 PassThrough。
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Theme.ResourceInterception;

internal sealed class ThemeLeafResourceRule : IResourceInterceptionRule
{
	private const int ExpectedClassTokenCount = 3;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex SkinPathPattern = new Regex(
		@"^/play/control/controlbarskin/skin(?<id>[0-9])(?:~[^/]*)?\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private readonly ThemeTemplate[] _themes = new ThemeTemplate[10];
	private int _selectedThemeId = -1;

	public ThemeLeafResourceRule(string themeDirectory)
	{
		for (int themeId = 0; themeId < _themes.Length; themeId++)
		{
			string path = Path.Combine(themeDirectory ?? string.Empty, "skin" + themeId + ".swf");
			if (File.Exists(path))
			{
				TryAddTemplate(themeId, File.ReadAllBytes(path));
			}
		}
	}

	internal ThemeLeafResourceRule(IEnumerable<KeyValuePair<int, byte[]>> themes)
	{
		if (themes == null)
		{
			throw new ArgumentNullException(nameof(themes));
		}
		foreach (KeyValuePair<int, byte[]> theme in themes)
		{
			if (theme.Key < 0 || theme.Key >= _themes.Length || !TryAddTemplate(theme.Key, theme.Value))
			{
				throw new ArgumentException("Theme templates must be valid FWS files with an exact SkinN contract.", nameof(themes));
			}
		}
	}

	public string Name => "theme.controlbar.leaf";

	public int Priority => 800;

	public string PathOwnership => "aola.100bt.com:/play/control/controlbarskin/skinN~*.swf";

	public int SelectedThemeId
	{
		get => Volatile.Read(ref _selectedThemeId);
		set
		{
			if (value < -1 || value >= _themes.Length)
			{
				throw new ArgumentOutOfRangeException(nameof(value));
			}
			if (value >= 0 && _themes[value] == null)
			{
				throw new InvalidOperationException("Theme " + value + " does not have a verified local SWF.");
			}
			Volatile.Write(ref _selectedThemeId, value);
		}
	}

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		int selectedThemeId = SelectedThemeId;
		if (selectedThemeId < 0 || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		Match match = SkinPathPattern.Match(request.Path);
		if (!match.Success || !int.TryParse(match.Groups["id"].Value, out int requestedSkinId))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		ThemeTemplate template = _themes[selectedThemeId];
		byte[] response = (byte[])template.Content.Clone();
		byte[] source = Encoding.ASCII.GetBytes("Skin" + selectedThemeId);
		byte[] target = Encoding.ASCII.GetBytes("Skin" + requestedSkinId);
		if (source.Length != target.Length || ReplaceSameLength(response, source, target) != ExpectedClassTokenCount ||
			!IsValidFws(response))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.LocalResponse(
			request.OriginalUrl,
			response,
			"application/x-shockwave-flash",
			"theme:" + template.Sha256 + ":skin" + requestedSkinId,
			"theme.controlbar.skin" + selectedThemeId + ".as.skin" + requestedSkinId);
	}

	private bool TryAddTemplate(int themeId, byte[] content)
	{
		if (!IsValidFws(content))
		{
			return false;
		}
		byte[] token = Encoding.ASCII.GetBytes("Skin" + themeId);
		if (CountOccurrences(content, token) != ExpectedClassTokenCount)
		{
			return false;
		}
		byte[] copy = (byte[])content.Clone();
		using SHA256 sha256 = SHA256.Create();
		_themes[themeId] = new ThemeTemplate(copy, ToLowerHex(sha256.ComputeHash(copy)));
		return true;
	}

	private static bool IsValidFws(byte[] content)
	{
		if (content == null || content.Length < 8 || content.Length > MaximumSwfBytes ||
			content[0] != 'F' || content[1] != 'W' || content[2] != 'S')
		{
			return false;
		}
		return BitConverter.ToUInt32(content, 4) == content.Length;
	}

	private static int ReplaceSameLength(byte[] content, byte[] search, byte[] replacement)
	{
		if (search.Length != replacement.Length)
		{
			return 0;
		}
		int count = 0;
		for (int offset = 0; offset <= content.Length - search.Length; offset++)
		{
			bool match = true;
			for (int index = 0; index < search.Length; index++)
			{
				if (content[offset + index] != search[index])
				{
					match = false;
					break;
				}
			}
			if (!match)
			{
				continue;
			}
			Buffer.BlockCopy(replacement, 0, content, offset, replacement.Length);
			count++;
			offset += search.Length - 1;
		}
		return count;
	}

	private static int CountOccurrences(byte[] content, byte[] value)
	{
		int count = 0;
		for (int offset = 0; offset <= content.Length - value.Length; offset++)
		{
			bool match = true;
			for (int index = 0; index < value.Length; index++)
			{
				if (content[offset + index] != value[index])
				{
					match = false;
					break;
				}
			}
			if (match)
			{
				count++;
				offset += value.Length - 1;
			}
		}
		return count;
	}

	private static string ToLowerHex(byte[] value)
	{
		StringBuilder builder = new StringBuilder(value.Length * 2);
		foreach (byte item in value)
		{
			builder.Append(item.ToString("x2"));
		}
		return builder.ToString();
	}

	private sealed class ThemeTemplate
	{
		public ThemeTemplate(byte[] content, string sha256)
		{
			Content = content;
			Sha256 = sha256;
		}

		public byte[] Content { get; }

		public string Sha256 { get; }
	}
}
