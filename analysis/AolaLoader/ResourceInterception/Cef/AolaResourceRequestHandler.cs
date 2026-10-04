// 架构角色：CEF 资源入口与规则装配点，集中注册 Theme、ActiveSend、Battle、PetMorph 规则。
// 数据流：CEF request callbacks -> ResourceRulePipeline/Cef adapter -> 官方、远端改写或本地响应。
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using CefSharp.Handler;
using AolaLoader.Features.ActiveSend.ResourceInterception;
using AolaLoader.Features.Battle.ResourceInterception;
using AolaLoader.Features.Battle.Coordination;
using AolaLoader.Features.Battle.Settings;
using AolaLoader.Features.PetMorph;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.PetMorph.ResourceInterception;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.ResourceInterception;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;

namespace AolaLoader.ResourceInterception.Cef;

internal sealed class AolaResourceRequestHandler : RequestHandler, IThemeSelectionTarget, IPetMorphRuleTarget, IBattleMorphRuleTarget
{
	private const int HiddenPetMovieTemplateId = 6025;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private const string SupportedPosterResourceSuffix = "~1210";
	private readonly ThemeLeafResourceRule _themeRule;
	private readonly StartBridgeResourceRule _startBridgeRule;
	private readonly PetFightBattleBridgeResourceRule _battleBridgeRule;
	private readonly BattleBackgroundImageResourceRule _battleBackgroundRule;
	private readonly BattlePetMovieResourceRule _battlePetMovieRule;
	private readonly BattlePetMovieVersionCatalog _battlePetMovieCatalog;
	private readonly PetPackageLiveResourceRule _petPackageRule;
	private readonly PetMovieResourceRule _petMovieRule;
	private readonly PetPosterResourceRule _petPosterRule;
	private readonly IRemoteResourceProbe _remoteResourceProbe;
	private readonly IRemoteResourceFetcher _remoteResourceFetcher;
	private readonly CefResourceRuleAdapter _resourceRuleAdapter;
	private readonly AolaPetPosterCatalog _posterCatalog;
	private readonly bool _petMorphLiveBridgeEnabled;
	private readonly AolaSwfCaptureSession _swfCaptureSession;

	public AolaResourceRequestHandler(
		string themeDirectory,
		string posterCatalogPath,
		string startBridgeTemplatePath,
		string battleBridgeManifestPath,
		string battleBackgroundImagePath,
		string battlePetMovieCatalogPath,
		string petPackageLiveTemplatePath,
		bool petMorphLiveBridgeEnabled)
	{
		_themeRule = new ThemeLeafResourceRule(themeDirectory);
		bool liveTheme = !string.Equals(Environment.GetEnvironmentVariable("AOLA_THEME_LIVE_BRIDGE"), "0", StringComparison.Ordinal);
		_themeRule.LiveEnabled = liveTheme;
		var themeBridgeRule = new ThemeControlBridgeResourceRule(
			Path.Combine(themeDirectory, "..", "Patches", "controlv2-theme-live-2026082731219998.fws.swf"), liveTheme);
		_startBridgeRule = new StartBridgeResourceRule(startBridgeTemplatePath);
		_battleBridgeRule = new PetFightBattleBridgeResourceRule(battleBridgeManifestPath);
		_battleBackgroundRule = new BattleBackgroundImageResourceRule(battleBackgroundImagePath);
		_battlePetMovieRule = new BattlePetMovieResourceRule();
		_battlePetMovieCatalog = BattlePetMovieVersionCatalog.Load(battlePetMovieCatalogPath);
		_petMorphLiveBridgeEnabled = petMorphLiveBridgeEnabled;
		_petPackageRule = new PetPackageLiveResourceRule(petPackageLiveTemplatePath);
		_petMovieRule = new PetMovieResourceRule();
		_posterCatalog = AolaPetPosterCatalog.Load(posterCatalogPath);
		_petPosterRule = new PetPosterResourceRule(_posterCatalog);
		_swfCaptureSession = AolaSwfCaptureSession.TryStart(AppDomain.CurrentDomain.BaseDirectory);
		_remoteResourceProbe = new CachingRemoteResourceProbe(new HttpSwfRemoteResourceProbe());
		_remoteResourceFetcher = new HttpRemoteResourceFetcher();
		_resourceRuleAdapter = new CefResourceRuleAdapter(new ResourceRulePipeline(
			new IResourceInterceptionRule[]
			{
				_startBridgeRule, _battleBridgeRule, _battleBackgroundRule, themeBridgeRule, _themeRule, _petPackageRule,
				_petMovieRule, _battlePetMovieRule, _petPosterRule
			}),
			new RemoteResourcePlanExecutor(_remoteResourceProbe, _remoteResourceFetcher));
	}

	public bool ThemeLiveEnabled => _themeRule.LiveEnabled;

	string IBattleMorphRuleTarget.ValidateRule(BattleMorphRule rule)
	{
		return ValidateBattleMorphRule(rule);
	}

	async Task<BattleMorphPreparationResult> IBattleMorphRuleTarget.PrepareRulesAsync(
		IReadOnlyList<BattleMorphRule> rules,
		bool enabled,
		CancellationToken cancellationToken)
	{
		if (!enabled)
		{
			return BattleMorphPreparationResult.Success(0, Array.Empty<PreparedBattleMorphRule>());
		}
		if (!_battlePetMovieCatalog.IsAvailable)
		{
			return BattleMorphPreparationResult.Failure(_battlePetMovieCatalog.Error);
		}
		BattleMorphRule[] snapshot = (rules ?? Array.Empty<BattleMorphRule>()).Where(rule => rule != null).ToArray();
		if (snapshot.Length == 0)
		{
			return BattleMorphPreparationResult.Failure("启用战斗模型替换时至少需要一条规则。");
		}
		if (snapshot.Select(rule => rule.SourceViewId).Distinct().Count() != snapshot.Length)
		{
			return BattleMorphPreparationResult.Failure("同一个战斗模型源 ID 只能配置一次。");
		}

		List<PreparedBattleMorphRule> prepared = new List<PreparedBattleMorphRule>();
		foreach (BattleMorphRule rule in snapshot)
		{
			string validation = ValidateBattleMorphRule(rule);
			if (validation != null) return BattleMorphPreparationResult.Failure(validation);
			Dictionary<int, string> versions = new Dictionary<int, string>();
			Dictionary<int, string> urls = new Dictionary<int, string>();
			List<Task<RemoteResourceProbeResult>> probes = new List<Task<RemoteResourceProbeResult>>();
			for (int face = 1; face <= 2; face++)
			{
				for (int part = 0; part <= 2; part++)
				{
					string path = "fightassets/bitmap/pet" + rule.TargetViewId + "/pet" +
						rule.TargetViewId + "_" + face + "_" + part;
					string version = _battlePetMovieCatalog.GetVersion(path);
					if (version == null)
					{
						return BattleMorphPreparationResult.Failure("无法解析目标战斗模型版本：" + path);
					}
					versions[face * 10 + part] = version;
					string url = "https://aola.100bt.com/play/" + path + "~" + version + ".swf";
					urls[face * 10 + part] = url;
					probes.Add(_remoteResourceProbe.ProbeAsync(
						new RemoteResourceProbeRequest(
							url,
							"battle-petmovie-preflight:" + rule.TargetViewId + ":" + face + ":" + part + ":" + version,
							"battle.petmovie.preflight." + rule.TargetViewId + "." + face + "." + part,
							MaximumSwfBytes,
							TimeSpan.FromMinutes(10),
							TimeSpan.FromSeconds(30)),
						cancellationToken));
				}
			}
			RemoteResourceProbeResult[] results = await Task.WhenAll(probes).ConfigureAwait(false);
			if (results.Any(result => result == null || !result.Available))
			{
				RemoteResourceProbeResult failed = results.FirstOrDefault(result => result == null || !result.Available);
				return BattleMorphPreparationResult.Failure(
					"目标模型 " + rule.TargetViewId + " 的六个战斗分片未全部通过检查：" +
					(failed?.Message ?? "无结果"));
			}
			Dictionary<int, Task<RemoteResourceFetchResult>> fetches = urls.ToDictionary(
				pair => pair.Key,
				pair => _remoteResourceFetcher.FetchAsync(
					new RemoteResourceFetchRequest(
						pair.Value,
						"battle.petmovie.prepare." + rule.TargetViewId + "." + pair.Key,
						MaximumSwfBytes),
					cancellationToken));
			await Task.WhenAll(fetches.Values).ConfigureAwait(false);
			Dictionary<int, byte[]> contents = new Dictionary<int, byte[]>();
			foreach (KeyValuePair<int, Task<RemoteResourceFetchResult>> item in fetches)
			{
				RemoteResourceFetchResult fetched = item.Value.Result;
				int part = item.Key % 10;
				if (fetched == null || !fetched.Succeeded)
				{
					return BattleMorphPreparationResult.Failure(
						"目标模型 " + rule.TargetViewId + " 的战斗分片下载失败：" +
						(fetched?.Message ?? "无结果"));
				}
				ResourceTransformResult transformed = new BattlePetMovieResourceTransformer(
					rule.SourceViewId,
					rule.TargetViewId,
					item.Key / 10,
					part).Transform(new ResourceTransformInput(
						urls[item.Key],
						fetched.HttpStatusCode ?? 200,
						fetched.ContentType,
						fetched.Content));
				if (!transformed.Succeeded)
				{
					return BattleMorphPreparationResult.Failure(
						"目标模型 " + rule.TargetViewId + " 的战斗分片类契约无效：" + transformed.Message);
				}
				contents[item.Key] = transformed.Content;
			}
			prepared.Add(new PreparedBattleMorphRule(rule, versions, contents));
		}
		return BattleMorphPreparationResult.Success(prepared.Count, prepared.ToArray());
	}

	void IBattleMorphRuleTarget.ActivatePreparedRules(BattleMorphPreparationResult preparation)
	{
		if (preparation == null || !preparation.Succeeded ||
			!(preparation.PreparedState is PreparedBattleMorphRule[] rules))
		{
			throw new ArgumentException("A successful battle morph preparation is required.", nameof(preparation));
		}
		_battlePetMovieRule.SetRules(rules, rules.Length > 0);
	}

	private static string ValidateBattleMorphRule(BattleMorphRule rule)
	{
		return BattleMorphRuleValidation.Validate(rule);
	}

	void IThemeSelectionTarget.SetSelectedThemeId(int themeId)
	{
		_themeRule.SelectedThemeId = themeId == 0 ? -1 : themeId;
	}

	void IPetMorphRuleTarget.SetRules(IReadOnlyList<AolaPetMorphRule> rules, bool enabled)
	{
		AolaPetMorphRule[] snapshot = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Select(rule => new AolaPetMorphRule(
				rule.Note, rule.OriginalId, rule.BackpackId, rule.PosterSourceId, rule.PosterId,
				rule.HideOriginalModel, rule.RemoveOriginalBackground, rule.ReplaceBackpackIcon))
			.ToArray();
		_petMovieRule.SetRules(snapshot, enabled);
		_petPosterRule.SetRules(snapshot, enabled);
	}

	bool IPetMorphRuleTarget.IsLiveBridgeAvailable => _petPackageRule.IsAvailable;

	string IPetMorphRuleTarget.ValidateRule(AolaPetMorphRule rule)
	{
		return ValidatePetMorphRule(rule);
	}

	Task<IReadOnlyDictionary<int, int>> IPetMorphRuleTarget.GetAvailableLiveSkinMappingsAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		return GetAvailableLiveSkinMappingsAsync(rules, enabled);
	}

	private async Task<IReadOnlyDictionary<int, int>> GetAvailableLiveSkinMappingsAsync(
		IEnumerable<AolaPetMorphRule> rules,
		bool enabled)
	{
		if (!enabled || !_petMorphLiveBridgeEnabled || !_petPackageRule.IsAvailable)
		{
			return new Dictionary<int, int>();
		}

		KeyValuePair<int, int>[] candidates = PetMorphLiveSkinMapping.BuildCandidates(rules).ToArray();

		Task<KeyValuePair<int, int>?>[] probes = candidates.Select(async pair =>
		{
			if (!_posterCatalog.TryGetBySkinId(pair.Value, out AolaPetPosterCatalogEntry target))
			{
				return (KeyValuePair<int, int>?)null;
			}
			string url = "https://aola.100bt.com/play/pet/petskin/background/petskinbackground" +
				target.ResourceId + SupportedPosterResourceSuffix + ".swf";
			RemoteResourceProbeResult result = await _remoteResourceProbe.ProbeAsync(
				new RemoteResourceProbeRequest(
					url,
					"live-skin:" + target.ResourceId,
					"petmorph.live-skin." + target.ResourceId,
					PetMorphLiveSkinMapping.MaximumBackgroundSwfBytes,
					TimeSpan.FromMinutes(10),
					TimeSpan.FromSeconds(30)),
				CancellationToken.None).ConfigureAwait(false);
			return result.Available ? pair : (KeyValuePair<int, int>?)null;
		}).ToArray();

		KeyValuePair<int, int>?[] results = await Task.WhenAll(probes).ConfigureAwait(false);
		return results.Where(item => item.HasValue)
			.Select(item => item.Value)
			.ToDictionary(pair => pair.Key, pair => pair.Value);
	}

	private string ValidatePetMorphRule(AolaPetMorphRule rule)
	{
		if (rule == null || (rule.BackpackId <= 0 && rule.PosterId <= 0 &&
			!rule.HideOriginalModel && !rule.RemoveOriginalBackground && !rule.ReplaceBackpackIcon))
		{
			return "原型 ID 无效。";
		}
		if (rule.RemoveOriginalBackground && rule.OriginalId <= 0)
		{
			return "移除原背景时必须填写模型源 ID。";
		}
		if (rule.ReplaceBackpackIcon && (rule.OriginalId <= 0 || rule.BackpackId <= 0))
		{
			return "替换背包头像时必须同时填写模型源 ID 和模型目标 ID。";
		}
		if (rule.BackpackId > 0 || rule.HideOriginalModel)
		{
			if (rule.OriginalId < 4400 || rule.BackpackId > 0 && rule.BackpackId < 4400)
			{
				return "背包动态模型仅支持 ID 大于等于 4400；较旧 ID 使用另一套静态资源格式。";
			}
			if (rule.BackpackId > 0 &&
				rule.OriginalId.ToString().Length != rule.BackpackId.ToString().Length)
			{
				return "背包原型 ID 与替换 ID 的位数必须一致，以保持 SWF 类名长度不变。";
			}
			if (rule.HideOriginalModel && rule.BackpackId > 0)
			{
				return "隐藏原模型与模型目标 ID 不能同时启用。";
			}
			if (rule.HideOriginalModel &&
				rule.OriginalId.ToString().Length != HiddenPetMovieTemplateId.ToString().Length)
			{
				return "隐藏原模型当前仅支持与透明模板同为 4 位数的模型 ID。";
			}
		}
		if (rule.PosterId > 0)
		{
			if (!_posterCatalog.IsAvailable)
			{
				return "Poster catalog is unavailable: " + (_posterCatalog.Error ?? "empty catalog");
			}
			if (rule.PosterSourceId > 0 &&
				!_posterCatalog.TryGetBySkinId(rule.PosterSourceId, out _))
			{
				return "Poster source skin ID is not present in the complete Background catalog.";
			}
			if (!_posterCatalog.TryGetBySkinId(rule.PosterId, out _))
			{
				return "Poster target skin ID is not present in the complete Background catalog.";
			}
			if (rule.PosterSourceId <= 0 && rule.OriginalId <= 0)
			{
				return "模型形态转海报时必须填写模型源 ID。";
			}
			return null;
		}
		return null;
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
		if (_swfCaptureSession != null &&
			AolaSwfCaptureSession.IsSwfUrl(request?.Url))
		{
			disableDefaultHandling = false;
			return _swfCaptureSession.CreateHandler(request);
		}
		return _resourceRuleAdapter.GetResourceRequestHandler(request, ref disableDefaultHandling);
	}
}
