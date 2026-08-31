using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using AolaLoader.ResourceInterception.Contracts;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class PetFightBattleBridgeResourceRule : IResourceInterceptionRule
{
	internal const string SupportedVersion = "2026082731219998";
	internal const string ExpectedTemplateSha256 =
		"5e9e1878f50acdcbcfc92f4dceea5136a2497ab0639b3a0481004de9e4191c74";
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex BattlePathPattern = new Regex(
		@"^/play/pet/petfightnew~(?<version>\d+)\.swf$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
	private static readonly string[] RequiredMarkers =
	{
		"aolaBattleBridgeReady",
		"aolaBattleApplyOptions",
		"aolaBattleGetState",
		"mmo.petfightnew.DocPetFight",
		"hideDamageNumbers",
		"hideHealingNumbers",
		"skipBattlePresentation",
		"noteInputReady"
	};
	private readonly byte[] _template;

	public PetFightBattleBridgeResourceRule(string templatePath)
	{
		if (!string.IsNullOrWhiteSpace(templatePath) && File.Exists(templatePath))
		{
			TrySetTemplate(File.ReadAllBytes(templatePath), out _template);
		}
	}

	internal PetFightBattleBridgeResourceRule(byte[] template)
	{
		if (!TrySetTemplate(template, out _template))
		{
			throw new ArgumentException(
				"Battle bridge template must be the verified bounded FWS candidate.",
				nameof(template));
		}
	}

	public string Name => "battle.petfight.bridge";

	public int Priority => 850;

	public string PathOwnership =>
		"aola.100bt.com:/play/pet/petfightnew~" + SupportedVersion + ".swf";

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

		Match match = BattlePathPattern.Match(request.Path);
		if (!match.Success ||
			!string.Equals(match.Groups["version"].Value, SupportedVersion, StringComparison.Ordinal))
		{
			return ResourceInterceptionPlan.PassThrough(request.OriginalUrl);
		}

		return ResourceInterceptionPlan.LocalResponse(
			request.OriginalUrl,
			_template,
			"application/x-shockwave-flash",
			"battle:petfight:" + SupportedVersion + ":" + ExpectedTemplateSha256,
			"battle.petfight.bridge." + SupportedVersion);
	}

	private static bool TrySetTemplate(byte[] content, out byte[] template)
	{
		template = null;
		if (!IsValidFws(content))
		{
			return false;
		}
		foreach (string marker in RequiredMarkers)
		{
			if (CountOccurrences(content, Encoding.ASCII.GetBytes(marker)) < 1)
			{
				return false;
			}
		}
		using SHA256 sha256 = SHA256.Create();
		string actualHash = ToLowerHex(sha256.ComputeHash(content));
		if (!string.Equals(actualHash, ExpectedTemplateSha256, StringComparison.Ordinal))
		{
			return false;
		}
		template = (byte[])content.Clone();
		return true;
	}

	private static bool IsValidFws(byte[] content)
	{
		return content != null && content.Length >= 8 && content.Length <= MaximumSwfBytes &&
			content[0] == 'F' && content[1] == 'W' && content[2] == 'S' &&
			BitConverter.ToUInt32(content, 4) == content.Length;
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
