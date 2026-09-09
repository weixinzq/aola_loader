using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaLoader.BrowserHost.Testing;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Settings;
using Newtonsoft.Json.Linq;

namespace AolaSocketHack.Verify;

internal static class BattleMorphCoordinatorVerifier
{
	public static bool Verify()
	{
		string root = Path.Combine(Path.GetTempPath(), "aola-battle-morph-coordinator-" + Guid.NewGuid().ToString("N"));
		Directory.CreateDirectory(root);
		try
		{
			bool active = true;
			bool ended = false;
			ManualPageBridge page = new ManualPageBridge();
			page.SetAvailability(PageBridgeAvailability.Ready);
			page.InvokeHandler = (request, token) =>
			{
				if (request.Operation == "battle.state")
				{
					return Task.FromResult(PageBridgeResult.Success(new JObject
					{
						["version"] = 5,
						["active"] = active,
						["battleId"] = 1,
						["turn"] = 0,
						["inputReady"] = active,
						["readyEpoch"] = 1,
						["ended"] = ended
					}));
				}
				int revision = request.Arguments.Value<int>("revision");
				return Task.FromResult(PageBridgeResult.Success(new JObject
				{
					["status"] = "BattleOptionsApplied",
					["revision"] = revision
				}));
			};
			ManualMorphTarget target = new ManualMorphTarget();
			BattlePresentationCoordinator coordinator = new BattlePresentationCoordinator(
				new JsonSettingsSectionStore(Path.Combine(root, "settings.json")),
				new BattleSettingsCodec(),
				new BattleBridgeClient(page),
				target);
			BattlePresentationApplyResult saved = coordinator.SaveAndApplyAsync(
				new BattleSettings(false, false, false, true, new[]
				{
					new BattleMorphRule("swap", 6000, 6047)
				}),
				CancellationToken.None).GetAwaiter().GetResult();
			if (!saved.Saved || !saved.BattleMorphActivationPending || target.ActivateCount != 0)
			{
				return false;
			}
			ended = true;
			active = false;
			if (coordinator.TryActivatePendingMorphRulesAsync(CancellationToken.None).GetAwaiter().GetResult() ||
				target.ActivateCount != 0)
			{
				return false;
			}
			ended = false;
			return coordinator.TryActivatePendingMorphRulesAsync(CancellationToken.None).GetAwaiter().GetResult() &&
				target.ActivateCount == 1 && target.LastPreparedRuleCount == 1 &&
				!coordinator.TryActivatePendingMorphRulesAsync(CancellationToken.None).GetAwaiter().GetResult();
		}
		finally
		{
			Directory.Delete(root, true);
		}
	}

	private sealed class ManualMorphTarget : IBattleMorphRuleTarget
	{
		public int ActivateCount { get; private set; }
		public int LastPreparedRuleCount { get; private set; }

		public string ValidateRule(BattleMorphRule rule) => BattleMorphRuleValidation.Validate(rule);

		public Task<BattleMorphPreparationResult> PrepareRulesAsync(
			IReadOnlyList<BattleMorphRule> rules,
			bool enabled,
			CancellationToken cancellationToken)
		{
			int count = enabled ? rules.Count : 0;
			return Task.FromResult(BattleMorphPreparationResult.Success(count, new object()));
		}

		public void ActivatePreparedRules(BattleMorphPreparationResult preparation)
		{
			ActivateCount++;
			LastPreparedRuleCount = preparation.PreparedRuleCount;
		}
	}
}
