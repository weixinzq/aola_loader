using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.PetMorph.ResourceInterception;

internal sealed class PetPackageLiveResourceRule : IResourceInterceptionRule
{
	internal const string SupportedVersion = "2026082731219998";
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex PackagePathPattern = new Regex(
		@"^/play/pet/newpetpackage~(?<version>\d+)\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly string[] RequiredBridgeMarkers =
	{
		"aolaMorphResolveSkinId",
		"aolaMorphRefresh",
		"aolaMorphShouldHideBackground",
		"aolaMorphResolveIconId",
		"aolaSendCommand",
		"aolaOpenPanel",
		"ensureAolaCommandBridge",
		"aolaCommandCompleted"
	};
	private readonly byte[] _template;
	private readonly string _sha256;

	public PetPackageLiveResourceRule(string templatePath)
	{
		if (!string.IsNullOrWhiteSpace(templatePath) && File.Exists(templatePath))
		{
			TrySetTemplate(File.ReadAllBytes(templatePath), out _template, out _sha256);
		}
	}

	internal PetPackageLiveResourceRule(byte[] template)
	{
		if (!TrySetTemplate(template, out _template, out _sha256))
		{
			throw new ArgumentException(
				"Pet package template must be a bounded FWS containing every required bridge marker.",
				nameof(template));
		}
	}

	public string Name => "petmorph.package.live";

	public int Priority => 699;

	public string PathOwnership =>
		"aola.100bt.com:/play/pet/newpetpackage~" + SupportedVersion + ".swf";

	public bool IsAvailable => _template != null;

	public ResourceInterceptionPlan Evaluate(ResourceRequestContext request)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		if (!IsAvailable || request.Method != "GET" ||
			!string.Equals(request.Host, "aola.100bt.com", StringComparison.OrdinalIgnoreCase))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		Match match = PackagePathPattern.Match(request.Path);
		if (!match.Success ||
			!string.Equals(match.Groups["version"].Value, SupportedVersion, StringComparison.Ordinal))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.LocalResponse(
			request.OriginalUrl,
			_template,
			"application/x-shockwave-flash",
			"petmorph:package:" + SupportedVersion + ":" + _sha256,
			"petmorph.package.live." + SupportedVersion);
	}

	private static bool TrySetTemplate(byte[] content, out byte[] template, out string sha256Hex)
	{
		template = null;
		sha256Hex = null;
		if (!IsValidFws(content))
		{
			return false;
		}
		foreach (string marker in RequiredBridgeMarkers)
		{
			if (CountOccurrences(content, Encoding.ASCII.GetBytes(marker)) < 1)
			{
				return false;
			}
		}

		template = (byte[])content.Clone();
		using SHA256 sha256 = SHA256.Create();
		sha256Hex = ToLowerHex(sha256.ComputeHash(template));
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
}
