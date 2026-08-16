using System;
using System.Collections.Generic;
using System.Linq;
using AolaSocketHack.Contracts;

namespace AolaLoader;

internal sealed class AolaBattleStateTracker : IDisposable
{
	private readonly object _syncRoot = new object();
	private AolaBattleSnapshot _snapshot = new AolaBattleSnapshot();
	private bool _disposed;

	public AolaBattleStateTracker()
	{
		AolaHookHostService.PacketReceived += OnPacketReceived;
	}

	public event Action<AolaBattleSnapshot> SnapshotChanged;

	public AolaBattleSnapshot CurrentSnapshot
	{
		get
		{
			lock (_syncRoot)
			{
				return _snapshot.Clone();
			}
		}
	}

	private void OnPacketReceived(AolaPacketEvent packet)
	{
		if (_disposed || !AolaBattlePacketParser.TryParse(packet, out AolaBattlePacketUpdate update))
		{
			return;
		}

		AolaBattleSnapshot published;
		lock (_syncRoot)
		{
			if (_disposed)
			{
				return;
			}
			ApplyUpdate(update);
			published = _snapshot.Clone();
		}

		try
		{
			SnapshotChanged?.Invoke(published);
		}
		catch (ObjectDisposedException)
		{
		}
		catch (InvalidOperationException)
		{
		}
	}

	private void ApplyUpdate(AolaBattlePacketUpdate update)
	{
		if (string.Equals(update.Command, "2303", StringComparison.Ordinal))
		{
			_snapshot = new AolaBattleSnapshot();
		}
		else if (update.StartsNewBattle)
		{
			_snapshot = CreateBattleSnapshotWithRecentRoster(update);
		}

		_snapshot.HasBattle = _snapshot.HasBattle || update.StartsNewBattle || update.Sides.Count != 0;
		_snapshot.IsEnded = update.EndsBattle;
		_snapshot.LastCommand = update.Command;
		_snapshot.LastDescription = update.Description;
		_snapshot.LastUpdatedUtc = update.TimestampUtc;
		if (!string.IsNullOrWhiteSpace(update.BattleUniqueId))
		{
			_snapshot.BattleUniqueId = update.BattleUniqueId;
		}
		if (update.SelfPmmId.HasValue)
		{
			_snapshot.SelfPmmId = update.SelfPmmId;
		}

		foreach (AolaBattleSideSnapshot incoming in update.Sides)
		{
			int existingIndex = _snapshot.Sides.FindIndex(side => side.PmmId == incoming.PmmId);
			if (existingIndex >= 0)
			{
				MergeIncrementalSide(_snapshot.Sides[existingIndex], incoming);
			}
			else
			{
				_snapshot.Sides.Add(incoming.Clone());
			}
		}

		if (!_snapshot.SelfPmmId.HasValue)
		{
			AolaBattleSideSnapshot positive = _snapshot.Sides.FirstOrDefault(side => side.PmmId > 0);
			AolaBattleSideSnapshot negative = _snapshot.Sides.FirstOrDefault(side => side.PmmId < 0);
			if (positive != null && negative != null)
			{
				_snapshot.SelfPmmId = positive.PmmId;
			}
		}

		foreach (AolaBattleSideSnapshot side in _snapshot.Sides)
		{
			if (_snapshot.SelfPmmId.HasValue)
			{
				side.SideName = side.PmmId == _snapshot.SelfPmmId.Value ? "己方" : "敌方";
			}
			else
			{
				side.SideName = side.PmmId < 0 ? "敌方" : "未知";
			}
		}
	}

	private AolaBattleSnapshot CreateBattleSnapshotWithRecentRoster(AolaBattlePacketUpdate update)
	{
		AolaBattleSnapshot next = new AolaBattleSnapshot();
		TimeSpan age = update.TimestampUtc - _snapshot.LastUpdatedUtc;
		bool recentRoster = (string.Equals(_snapshot.LastCommand, "2303", StringComparison.Ordinal) ||
			string.Equals(_snapshot.LastCommand, "2304", StringComparison.Ordinal)) &&
			_snapshot.LastUpdatedUtc != default && age >= TimeSpan.Zero && age <= TimeSpan.FromSeconds(10);
		bool sameParticipants = update.Sides.Any(incoming =>
			_snapshot.Sides.Any(existing => existing.PmmId == incoming.PmmId));
		if (recentRoster && sameParticipants)
		{
			foreach (AolaBattleSideSnapshot side in _snapshot.Sides)
			{
				next.Sides.Add(side.Clone());
			}
			next.SelfPmmId = _snapshot.SelfPmmId;
		}
		return next;
	}

	private static void MergeIncrementalSide(AolaBattleSideSnapshot target, AolaBattleSideSnapshot incoming)
	{
		target.LastHpChange = incoming.LastHpChange;
		target.LastHpChangeDetails = incoming.LastHpChangeDetails;
		target.LastHpChangeType = incoming.LastHpChangeType;
		foreach (AolaBattlePetSnapshot incomingPet in incoming.Pets)
		{
			if (incomingPet.BattleSlotId.HasValue && incomingPet.UniqueId != 0)
			{
				foreach (AolaBattlePetSnapshot occupied in target.Pets.Where(pet =>
					pet.BattleSlotId == incomingPet.BattleSlotId && pet.UniqueId != incomingPet.UniqueId))
				{
					occupied.BattleSlotId = null;
				}
			}

			int index = incomingPet.UniqueId != 0
				? target.Pets.FindIndex(pet => pet.UniqueId == incomingPet.UniqueId)
				: -1;
			if (index < 0 && incomingPet.BattleSlotId.HasValue)
			{
				index = target.Pets.FindIndex(pet => pet.BattleSlotId == incomingPet.BattleSlotId);
			}
			if (index >= 0)
			{
				AolaBattlePetSnapshot replacement = incomingPet.Clone();
				if (!replacement.BattleSlotId.HasValue && target.Pets[index].BattleSlotId.HasValue)
				{
					replacement.BattleSlotId = target.Pets[index].BattleSlotId;
				}
				target.Pets[index] = replacement;
			}
			else
			{
				target.Pets.Add(incomingPet.Clone());
			}
		}
	}

	public void Dispose()
	{
		AolaHookHostService.PacketReceived -= OnPacketReceived;
		lock (_syncRoot)
		{
			_disposed = true;
			SnapshotChanged = null;
		}
	}
}
