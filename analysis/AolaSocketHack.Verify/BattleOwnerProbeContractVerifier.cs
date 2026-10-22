using System;
using AolaLoader.BrowserHost;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

/// <summary>
/// Owner probe contract: the env-gated resource rule must default to PassThrough,
/// and the page bridge must expose a strictly validated battle.probeRelease call.
/// </summary>
internal static class BattleOwnerProbeContractVerifier
{
	private static readonly string[] RequiredScriptTokens =
	{
		"operation === 'battle.probeRelease'",
		"findFlash('aolaBattleProbeRelease')",
		"aolaBattleProbeRelease(probeMode)",
		"Number(probe.version) !== 1",
		"Number(probe.mode) !== probeMode",
		"validProbeSnapshot(probe.before)",
		"validProbeSnapshot(probe.after)",
		"validProbeActions(probe.actions)",
		"probe.errors.length > 8"
	};

	public static bool Verify()
	{
		string script = AolaPageBridge.BuildInvocationScript(
			"battle.probeRelease",
			new JObject { ["mode"] = 1 });
		foreach (string token in RequiredScriptTokens)
		{
			if (script.IndexOf(token, StringComparison.Ordinal) < 0)
			{
				Console.Error.WriteLine("Owner probe page bridge script is missing " + token + ".");
				return false;
			}
		}
		return ResourceInterceptionContractVerifier.VerifyBattleOwnerProbeRule();
	}
}
