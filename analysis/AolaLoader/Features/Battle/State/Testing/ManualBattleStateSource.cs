// 架构角色：IBattleStateSource 的手工测试替身，可设置快照并同步触发变更事件。
// 数据流：测试输入 snapshot -> 被测 feature consumer。
using System;

namespace AolaLoader.Features.Battle.State.Testing;

internal sealed class ManualBattleStateSource : IBattleStateSource
{
	private readonly object _sync = new object();
	private AolaBattleSnapshot _snapshot;
	private Action<AolaBattleSnapshot> _snapshotChanged;
	private bool _disposed;

	public ManualBattleStateSource(AolaBattleSnapshot initialSnapshot = null)
	{
		_snapshot = (initialSnapshot ?? new AolaBattleSnapshot()).Clone();
	}

	public AolaBattleSnapshot CurrentSnapshot
	{
		get
		{
			lock (_sync)
			{
				ThrowIfDisposed();
				return _snapshot.Clone();
			}
		}
	}

	public event Action<AolaBattleSnapshot> SnapshotChanged
	{
		add
		{
			if (value == null)
			{
				return;
			}
			lock (_sync)
			{
				ThrowIfDisposed();
				_snapshotChanged += value;
			}
		}
		remove
		{
			lock (_sync)
			{
				if (!_disposed)
				{
					_snapshotChanged -= value;
				}
			}
		}
	}

	public void PublishSnapshot(AolaBattleSnapshot snapshot)
	{
		if (snapshot == null)
		{
			throw new ArgumentNullException(nameof(snapshot));
		}

		Action<AolaBattleSnapshot> handlers;
		AolaBattleSnapshot publishedSnapshot;
		lock (_sync)
		{
			ThrowIfDisposed();
			_snapshot = snapshot.Clone();
			publishedSnapshot = _snapshot;
			handlers = _snapshotChanged;
		}

		if (handlers == null)
		{
			return;
		}

		foreach (Action<AolaBattleSnapshot> handler in handlers.GetInvocationList())
		{
			try
			{
				handler(publishedSnapshot.Clone());
			}
			catch
			{
				// A faulty observer must not prevent other consumers from receiving a snapshot.
			}
		}
	}

	public void Dispose()
	{
		lock (_sync)
		{
			if (_disposed)
			{
				return;
			}
			_disposed = true;
			_snapshotChanged = null;
		}
	}

	private void ThrowIfDisposed()
	{
		if (_disposed)
		{
			throw new ObjectDisposedException(nameof(ManualBattleStateSource));
		}
	}
}
