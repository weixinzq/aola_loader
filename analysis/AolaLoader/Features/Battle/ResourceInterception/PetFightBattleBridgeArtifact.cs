// 架构角色：加载并验证 petfight bridge manifest、候选 SWF 长度、哈希和标记契约。
// 数据流：manifest + candidate bytes -> 已验证 artifact；任何不一致均拒绝替换。
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.Battle.ResourceInterception;

internal sealed class PetFightBattleBridgeArtifact
{
	internal const string ManifestFileName = "petfightnew-battle-state.current.json";
	internal const string CandidateFileName = "petfightnew-battle-visual-260924918360271.fws.swf";
	private const int ManifestSchemaVersion = 1;
	private const int BridgeVersion = 5;
	private const int MaximumManifestBytes = 16 * 1024;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private static readonly Regex VersionPattern = new Regex(
		@"^\d{1,32}$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private static readonly Regex Sha256Pattern = new Regex(
		@"^[0-9a-f]{64}$",
		RegexOptions.Compiled | RegexOptions.CultureInvariant);
	private static readonly string[] ManifestFields =
	{
		"schemaVersion",
		"resourceVersion",
		"officialUrl",
		"officialZwsSha256",
		"candidateFile",
		"candidateLength",
		"candidateSha256",
		"bridgeVersion",
		"symbolClassSha256"
	};
	private static readonly MarkerExpectation[] MarkerExpectations =
	{
		new MarkerExpectation("aolaBattleBridgeReady", 1),
		new MarkerExpectation("aolaBattleApplyOptions", 1),
		new MarkerExpectation("aolaBattleGetState", 1),
		new MarkerExpectation("mmo.petfightnew.DocPetFight", 1),
		new MarkerExpectation("mmo.petfightnew.common.FightPanel", 1),
		new MarkerExpectation("ensureAolaBattleBridge", 2),
		new MarkerExpectation("noteInputReady", 2),
		new MarkerExpectation("skipBattlePresentation", 1),
		new MarkerExpectation("hideDamageNumbers", 1),
		new MarkerExpectation("hideHealingNumbers", 1)
	};
	private static readonly string[] ForbiddenMarkers =
	{
		"skipPetAttackActions",
		"skipBattleVisualDelays",
		"skipAttackAnimation"
	};

	private PetFightBattleBridgeArtifact(
		string resourceVersion,
		string candidateSha256,
		byte[] content)
	{
		ResourceVersion = resourceVersion;
		CandidateSha256 = candidateSha256;
		Content = (byte[])content.Clone();
	}

	public string ResourceVersion { get; }

	public string CandidateSha256 { get; }

	public byte[] Content { get; }

	public static bool TryLoad(string manifestPath, out PetFightBattleBridgeArtifact artifact)
	{
		artifact = null;
		try
		{
			if (string.IsNullOrWhiteSpace(manifestPath) || !File.Exists(manifestPath))
			{
				return false;
			}
			FileInfo manifestFile = new FileInfo(manifestPath);
			if (manifestFile.Length <= 0 || manifestFile.Length > MaximumManifestBytes ||
				!TryParseManifest(File.ReadAllText(manifestFile.FullName, Encoding.UTF8), out Manifest manifest))
			{
				return false;
			}

			string manifestDirectory = Path.GetFullPath(manifestFile.DirectoryName ?? string.Empty);
			string candidatePath = Path.GetFullPath(Path.Combine(manifestDirectory, manifest.CandidateFile));
			if (!string.Equals(
				Path.GetDirectoryName(candidatePath),
				manifestDirectory,
				StringComparison.OrdinalIgnoreCase) ||
				!File.Exists(candidatePath) ||
				new FileInfo(candidatePath).Length != manifest.CandidateLength)
			{
				return false;
			}

			return TryCreate(manifest, File.ReadAllBytes(candidatePath), out artifact);
		}
		catch (Exception exception) when (
			exception is IOException ||
			exception is UnauthorizedAccessException ||
			exception is JsonException ||
			exception is ArgumentException ||
			exception is NotSupportedException)
		{
			artifact = null;
			return false;
		}
	}

	internal static PetFightBattleBridgeArtifact ParseForTesting(string manifestJson, byte[] content)
	{
		if (!TryParseManifest(manifestJson, out Manifest manifest) ||
			!TryCreate(manifest, content, out PetFightBattleBridgeArtifact artifact))
		{
			throw new ArgumentException(
				"Battle bridge manifest and template must be the verified bounded current artifact.",
				nameof(content));
		}
		return artifact;
	}

	private static bool TryParseManifest(string json, out Manifest manifest)
	{
		manifest = null;
		if (string.IsNullOrWhiteSpace(json) || Encoding.UTF8.GetByteCount(json) > MaximumManifestBytes)
		{
			return false;
		}

		JObject document;
		try
		{
			document = JObject.Parse(json, new JsonLoadSettings
			{
				DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error
			});
		}
		catch (JsonException)
		{
			return false;
		}
		if (document.Properties().Count() != ManifestFields.Length ||
			document.Properties().Any(property => !ManifestFields.Contains(property.Name, StringComparer.Ordinal)))
		{
			return false;
		}

		if (!TryGetInteger(document, "schemaVersion", out long schemaVersion) ||
			schemaVersion != ManifestSchemaVersion ||
			!TryGetInteger(document, "bridgeVersion", out long bridgeVersion) ||
			bridgeVersion != BridgeVersion ||
			!TryGetInteger(document, "candidateLength", out long candidateLength) ||
			candidateLength < 8 || candidateLength > MaximumSwfBytes ||
			!TryGetString(document, "resourceVersion", out string resourceVersion) ||
			!VersionPattern.IsMatch(resourceVersion) ||
			!TryGetString(document, "officialUrl", out string officialUrl) ||
			!TryGetString(document, "officialZwsSha256", out string officialZwsSha256) ||
			!Sha256Pattern.IsMatch(officialZwsSha256) ||
			!TryGetString(document, "candidateFile", out string candidateFile) ||
			!string.Equals(candidateFile, CandidateFileName, StringComparison.Ordinal) ||
			!TryGetString(document, "candidateSha256", out string candidateSha256) ||
			!Sha256Pattern.IsMatch(candidateSha256) ||
			!TryGetString(document, "symbolClassSha256", out string symbolClassSha256) ||
			!Sha256Pattern.IsMatch(symbolClassSha256))
		{
			return false;
		}

		string expectedUrl =
			"https://aola.100bt.com/play/pet/petfightnew~" + resourceVersion + ".swf";
		if (!string.Equals(officialUrl, expectedUrl, StringComparison.Ordinal))
		{
			return false;
		}

		manifest = new Manifest(resourceVersion, candidateFile, candidateLength, candidateSha256);
		return true;
	}

	private static bool TryCreate(
		Manifest manifest,
		byte[] content,
		out PetFightBattleBridgeArtifact artifact)
	{
		artifact = null;
		if (!IsValidFws(content) || content.LongLength != manifest.CandidateLength)
		{
			return false;
		}
		foreach (MarkerExpectation expectation in MarkerExpectations)
		{
			if (CountOccurrences(content, Encoding.ASCII.GetBytes(expectation.Value)) != expectation.Count)
			{
				return false;
			}
		}
		foreach (string marker in ForbiddenMarkers)
		{
			if (CountOccurrences(content, Encoding.ASCII.GetBytes(marker)) != 0)
			{
				return false;
			}
		}
		using SHA256 sha256 = SHA256.Create();
		string actualHash = ToLowerHex(sha256.ComputeHash(content));
		if (!string.Equals(actualHash, manifest.CandidateSha256, StringComparison.Ordinal))
		{
			return false;
		}
		artifact = new PetFightBattleBridgeArtifact(
			manifest.ResourceVersion,
			manifest.CandidateSha256,
			content);
		return true;
	}

	private static bool TryGetString(JObject document, string name, out string value)
	{
		value = null;
		JToken token = document[name];
		if (token?.Type != JTokenType.String)
		{
			return false;
		}
		value = token.Value<string>();
		return value != null;
	}

	private static bool TryGetInteger(JObject document, string name, out long value)
	{
		value = 0;
		JToken token = document[name];
		if (token?.Type != JTokenType.Integer)
		{
			return false;
		}
		value = token.Value<long>();
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

	private sealed class Manifest
	{
		public Manifest(
			string resourceVersion,
			string candidateFile,
			long candidateLength,
			string candidateSha256)
		{
			ResourceVersion = resourceVersion;
			CandidateFile = candidateFile;
			CandidateLength = candidateLength;
			CandidateSha256 = candidateSha256;
		}

		public string ResourceVersion { get; }
		public string CandidateFile { get; }
		public long CandidateLength { get; }
		public string CandidateSha256 { get; }
	}

	private sealed class MarkerExpectation
	{
		public MarkerExpectation(string value, int count)
		{
			Value = value;
			Count = count;
		}

		public string Value { get; }
		public int Count { get; }
	}
}
