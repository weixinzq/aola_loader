using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using CefSharp;
using CefSharp.Handler;
using AolaLoader.Features.PetMorph;
using AolaLoader.Features.PetMorph.Coordination;
using AolaLoader.Features.PetMorph.ResourceInterception;
using AolaLoader.Features.Theme.Coordination;
using AolaLoader.Features.Theme.ResourceInterception;
using AolaLoader.ResourceInterception.Contracts;
using AolaLoader.ResourceInterception.Pipeline;

namespace AolaLoader.ResourceInterception.Cef;

internal sealed class AolaResourceRequestHandler : RequestHandler, IThemeSelectionTarget, IPetMorphRuleTarget
{
	private const int HiddenPetMovieTemplateId = 6025;
	private const int MaximumSwfBytes = 16 * 1024 * 1024;
	private const string SupportedPosterResourceSuffix = "~1210";
	private readonly ThemeLeafResourceRule _themeRule;
	private readonly PetPackageLiveResourceRule _petPackageRule;
	private readonly PetMovieResourceRule _petMovieRule;
	private readonly PetPosterResourceRule _petPosterRule;
	private readonly IRemoteResourceProbe _remoteResourceProbe;
	private readonly CefResourceRuleAdapter _resourceRuleAdapter;
	private readonly AolaPetPosterCatalog _posterCatalog;
	private readonly bool _petMorphLiveBridgeEnabled;

	public AolaResourceRequestHandler(
		string themeDirectory,
		string posterCatalogPath,
		string petPackageLiveTemplatePath,
		bool petMorphLiveBridgeEnabled)
	{
		_themeRule = new ThemeLeafResourceRule(themeDirectory);
		_petMorphLiveBridgeEnabled = petMorphLiveBridgeEnabled;
		_petPackageRule = new PetPackageLiveResourceRule(
			_petMorphLiveBridgeEnabled ? petPackageLiveTemplatePath : null);
		_petMovieRule = new PetMovieResourceRule();
		_posterCatalog = AolaPetPosterCatalog.Load(posterCatalogPath);
		_petPosterRule = new PetPosterResourceRule(_posterCatalog);
		_remoteResourceProbe = new CachingRemoteResourceProbe(new HttpSwfRemoteResourceProbe());
		_resourceRuleAdapter = new CefResourceRuleAdapter(new ResourceRulePipeline(
			new IResourceInterceptionRule[] { _themeRule, _petPackageRule, _petMovieRule, _petPosterRule }),
			new RemoteResourcePlanExecutor(_remoteResourceProbe, new HttpRemoteResourceFetcher()));
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

	Task<IReadOnlyDictionary<int, int>> IPetMorphRuleTarget.GetAvailableLivePosterMappingsAsync(
		IReadOnlyList<AolaPetMorphRule> rules,
		bool enabled)
	{
		return GetAvailableLivePosterMappingsAsync(rules, enabled);
	}

	private async Task<IReadOnlyDictionary<int, int>> GetAvailableLivePosterMappingsAsync(
		IEnumerable<AolaPetMorphRule> rules,
		bool enabled)
	{
		if (!enabled || !_petMorphLiveBridgeEnabled || !_petPackageRule.IsAvailable)
		{
			return new Dictionary<int, int>();
		}

		KeyValuePair<int, int>[] candidates = (rules ?? Enumerable.Empty<AolaPetMorphRule>())
			.Where(rule => rule != null && rule.PosterId > 0)
			.Select(rule => new KeyValuePair<int, int>(
				rule.PosterSourceId > 0 ? rule.PosterSourceId : rule.OriginalId,
				rule.PosterId))
			.Where(pair => pair.Key > 0 && pair.Value > 0)
			.GroupBy(pair => pair.Key)
			.Select(group => group.Last())
			.ToArray();

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
					"live-poster:" + target.ResourceId,
					"petmorph.live-poster." + target.ResourceId,
					MaximumSwfBytes,
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
		return _resourceRuleAdapter.GetResourceRequestHandler(request, ref disableDefaultHandling);
	}
}
