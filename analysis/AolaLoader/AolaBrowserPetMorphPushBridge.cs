using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.PetMorph.Coordination;
using CefSharp;

namespace AolaLoader;

/// <summary>
/// Cef adapter that satisfies the PetMorph push seam with the live bridge and the
/// main frame from the production browser.
/// </summary>
internal sealed class AolaBrowserPetMorphPushBridge : IPetMorphPushBridge
{
	private readonly Func<IFrame> _mainFrameProvider;
	private readonly AolaPetMorphLiveBridge _liveBridge;

	public AolaBrowserPetMorphPushBridge(Func<IFrame> mainFrameProvider, AolaPetMorphLiveBridge liveBridge)
	{
		_mainFrameProvider = mainFrameProvider ?? throw new ArgumentNullException(nameof(mainFrameProvider));
		_liveBridge = liveBridge ?? throw new ArgumentNullException(nameof(liveBridge));
	}

	public async Task<AolaPetMorphPushResult> PushAsync(
		IReadOnlyDictionary<int, int> skinMappings,
		IReadOnlyDictionary<int, bool> hiddenBackgrounds,
		IReadOnlyDictionary<int, int> iconMappings,
		bool enabled,
		CancellationToken cancellationToken)
	{
		IFrame frame = _mainFrameProvider();
		if (frame == null || !frame.IsValid)
		{
			return AolaPetMorphPushResult.NotInjected("浏览器主框架尚未就绪。");
		}
		return await _liveBridge.PushAsync(
			frame,
			skinMappings,
			hiddenBackgrounds,
			iconMappings,
			enabled).ConfigureAwait(false);
	}
}
