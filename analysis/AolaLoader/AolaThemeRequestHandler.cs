using System;
using System.IO;
using System.Text;
using System.Threading;
using CefSharp;
using CefSharp.Handler;

namespace AolaLoader;

internal sealed class AolaThemeRequestHandler : RequestHandler
{
	private readonly byte[][] _themes = new byte[10][];
	private int _selectedThemeId = -1;

	public AolaThemeRequestHandler(string themeDirectory)
	{
		for (int themeId = 0; themeId < _themes.Length; themeId++)
		{
			string path = Path.Combine(themeDirectory ?? string.Empty, "skin" + themeId + ".swf");
			if (File.Exists(path))
			{
				byte[] content = File.ReadAllBytes(path);
				if (content.Length >= 8 && Encoding.ASCII.GetString(content, 0, 3) == "FWS")
				{
					_themes[themeId] = content;
				}
			}
		}
	}

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
				throw new InvalidOperationException("找不到主题 " + value + " 的本地 SWF。");
			}
			Volatile.Write(ref _selectedThemeId, value);
		}
	}

	protected override IResourceRequestHandler GetResourceRequestHandler(
		IWebBrowser chromiumWebBrowser,
		IBrowser browser,
		IFrame frame,
		IRequest request,
		bool isNavigation,
		bool isDownload,
		string requestInitiator,
		ref bool disableDefaultHandling)
	{
		int selectedThemeId = SelectedThemeId;
		if (selectedThemeId < 0 || !TryGetRequestedSkinId(request?.Url, out int requestedSkinId))
		{
			return null;
		}

		byte[] response = CreateSkinResponse(selectedThemeId, requestedSkinId);
		if (response == null)
		{
			return null;
		}
		disableDefaultHandling = true;
		return new SkinResourceRequestHandler(response);
	}

	private byte[] CreateSkinResponse(int selectedThemeId, int requestedSkinId)
	{
		byte[] source = _themes[selectedThemeId];
		if (source == null)
		{
			return null;
		}

		byte[] response = (byte[])source.Clone();
		byte[] sourceClass = Encoding.ASCII.GetBytes("Skin" + selectedThemeId);
		byte[] targetClass = Encoding.ASCII.GetBytes("Skin" + requestedSkinId);
		int replacements = ReplaceSameLength(response, sourceClass, targetClass);
		return replacements == 0 ? null : response;
	}

	private static int ReplaceSameLength(byte[] content, byte[] search, byte[] replacement)
	{
		if (search.Length != replacement.Length)
		{
			throw new ArgumentException("SWF 类名替换必须保持长度一致");
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

	private static bool TryGetRequestedSkinId(string url, out int skinId)
	{
		skinId = -1;
		if (!Uri.TryCreate(url, UriKind.Absolute, out Uri uri) ||
			!string.Equals(uri.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase) ||
			!uri.AbsolutePath.StartsWith("/play/control/controlbarskin/", StringComparison.OrdinalIgnoreCase))
		{
			return false;
		}

		string fileName = Path.GetFileName(uri.AbsolutePath);
		if (fileName.Length < 9 || !fileName.StartsWith("skin", StringComparison.OrdinalIgnoreCase) ||
			fileName[4] < '0' || fileName[4] > '9' ||
			(fileName[5] != '~' && fileName[5] != '.'))
		{
			return false;
		}
		skinId = fileName[4] - '0';
		return fileName.EndsWith(".swf", StringComparison.OrdinalIgnoreCase);
	}

	private sealed class SkinResourceRequestHandler : ResourceRequestHandler
	{
		private readonly byte[] _content;

		public SkinResourceRequestHandler(byte[] content)
		{
			_content = content;
		}

		protected override IResourceHandler GetResourceHandler(
			IWebBrowser chromiumWebBrowser,
			IBrowser browser,
			IFrame frame,
			IRequest request)
		{
			return ResourceHandler.FromByteArray(_content, "application/x-shockwave-flash");
		}
	}
}
