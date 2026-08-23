using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace AolaLoader.Features.PetMorph.Coordination.Testing;

/// <summary>
/// In-memory IPetMorphPushBridge double for coordinator verification.
/// </summary>
internal sealed class ManualPetMorphPushBridge : IPetMorphPushBridge
{
	private readonly List<PushCall> _calls = new List<PushCall>();

	public ManualPetMorphPushBridge(AolaPetMorphPushResult result = null)
	{
		Result = result ?? AolaPetMorphPushResult.NotInjected("simulated bridge not ready");
	}

	public AolaPetMorphPushResult Result { get; set; }

	public IReadOnlyList<PushCall> Calls => _calls;

	public int PushCallCount => _calls.Count;

	public Task<AolaPetMorphPushResult> PushAsync(
		IReadOnlyDictionary<int, int> skinMappings,
		IReadOnlyDictionary<int, bool> hiddenBackgrounds,
		IReadOnlyDictionary<int, int> iconMappings,
		bool enabled,
		CancellationToken cancellationToken)
	{
		_calls.Add(new PushCall(skinMappings, hiddenBackgrounds, iconMappings, enabled, cancellationToken));
		return Task.FromResult(Result);
	}

	internal sealed class PushCall
	{
		public PushCall(
			IReadOnlyDictionary<int, int> skinMappings,
			IReadOnlyDictionary<int, bool> hiddenBackgrounds,
			IReadOnlyDictionary<int, int> iconMappings,
			bool enabled,
			CancellationToken cancellationToken)
		{
			SkinMappings = skinMappings;
			HiddenBackgrounds = hiddenBackgrounds;
			IconMappings = iconMappings;
			Enabled = enabled;
			CancellationToken = cancellationToken;
		}

		public IReadOnlyDictionary<int, int> SkinMappings { get; }

		public IReadOnlyDictionary<int, bool> HiddenBackgrounds { get; }

		public IReadOnlyDictionary<int, int> IconMappings { get; }

		public bool Enabled { get; }

		public CancellationToken CancellationToken { get; }
	}
}
