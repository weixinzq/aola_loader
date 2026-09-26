// 架构角色：承载页面形态桥一次推送的成功、待处理和失败信息。
// 数据流：AolaPetMorphLiveBridge -> PetMorphCoordinator -> UI。
namespace AolaLoader.Features.PetMorph.Coordination;

/// <summary>
/// Framework-free outcome of a PetMorph page push. The Cef live-bridge adapter
/// produces this result; consumers must not touch CefSharp types.
/// </summary>
internal sealed class AolaPetMorphPushResult
{
	public AolaPetMorphPushResult(
		bool injected,
		bool bridgeReady,
		bool refreshInvoked,
		long revision,
		string error,
		bool superseded = false)
	{
		Injected = injected;
		BridgeReady = bridgeReady;
		RefreshInvoked = refreshInvoked;
		Revision = revision;
		Error = error;
		Superseded = superseded;
	}

	public bool Injected { get; }
	public bool BridgeReady { get; }
	public bool RefreshInvoked { get; }
	public long Revision { get; }
	public string Error { get; }
	public bool Superseded { get; }

	public static AolaPetMorphPushResult NotInjected(string error)
	{
		return new AolaPetMorphPushResult(false, false, false, 0, error);
	}

	public static AolaPetMorphPushResult SupersededResult()
	{
		return new AolaPetMorphPushResult(false, false, false, 0, null, true);
	}
}
