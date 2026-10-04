// 架构角色：统一执行文本步骤、战斗入口确认与整组重复，不拥有游戏连接。
// 数据流：已解析步骤 + ExecutionState -> IAolaCommandSender / battle bridge；取消仅停止文本。
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.Features.Battle.Bridge;
using AolaLoader.Features.Battle.Replay;
using AolaLoader.PacketHost;
using Newtonsoft.Json.Linq;
namespace AolaLoader.Features.ActiveSend;

internal sealed class AolaTextSequenceRunner
{
	private readonly AolaExecutionState _state;
	private readonly IAolaCommandSender _sender;
	private readonly BattleBridgeClient _bridge;
	private readonly BattleSequenceRunner _battleRunner;
	private int _running;
	public AolaTextSequenceRunner(IAolaPacketEventSource source, AolaExecutionState state,
		IAolaCommandSender sender, BattleBridgeClient bridge)
	{ _state = state; _sender = sender; _bridge = bridge; _battleRunner = new BattleSequenceRunner(source, sender, bridge); }
	public event Action<string> StatusChanged;
	private void Publish(string text) => StatusChanged?.Invoke(text);
	public async Task RunAsync(IReadOnlyList<AolaTextStep> steps, int groupCount, int restMilliseconds, CancellationToken token)
	{
		// 完整检查发生在首条提交之前；本地指令不进入网络 sender。
		BattleSequenceValidator.ValidateTextSteps(steps);
		if (Interlocked.CompareExchange(ref _running, 1, 0) != 0)
			throw new InvalidOperationException("文本序列正在执行。");
		var clock = Stopwatch.StartNew();
		double nextSendAt = 0;
		long connectionEpoch = _state.Current.SessionEpoch;
		long attachedBattleEpoch = -1;
		int attachedRoute = 0;
		try
		{
			for (int group = 0; group < groupCount; group++)
			{
				for (int index = 0; index < steps.Count; index++)
				{
					token.ThrowIfCancellationRequested();
					CheckConnection(connectionEpoch);
					var step = steps[index];
					Publish(string.Format("第 {0}/{1} 组，第 {2}/{3} 步（第 {4} 行）", group + 1, groupCount, index + 1, steps.Count, step.Line));
					if (step.Kind == AolaTextStepKind.Delay)
					{
						Publish(string.Format("暂停文本序列 {0:g} 秒；Flash 自动战斗继续。", step.Seconds));
						// Task.Delay 的单次毫秒范围有限，长暂停分段且每次检查连接。
						double remaining = step.Seconds * 1000;
						while (remaining > 0)
						{
							int slice = (int)Math.Min(remaining, 1000);
							await Task.Delay(Math.Max(1, slice), token).ConfigureAwait(false);
							remaining -= Math.Max(1, slice);
							CheckConnection(connectionEpoch);
						}
						continue;
					}
					if (step.Kind == AolaTextStepKind.WaitBattleEnd)
					{
						Publish("等待当前战斗自然结束；不发送 1404。");
						await WaitForEndAsync(connectionEpoch, token).ConfigureAwait(false);
						attachedBattleEpoch = -1; attachedRoute = 0;
						continue;
					}
					var request = step.Request;
					if (request.ExtensionId == 16 && request.Command == "preFightLoad")
					{ Publish("已跳过 preFightLoad；由 Flash 自行发送。"); continue; }
					double gap = nextSendAt - clock.Elapsed.TotalMilliseconds;
					if (gap > 0) await Task.Delay(TimeSpan.FromMilliseconds(Math.Ceiling(gap)), token).ConfigureAwait(false);
					CheckConnection(connectionEpoch);
					if (request.ExtensionId == 15 && request.Command == "54_22")
					{
						_state.BeginEntry();
						Publish("等待新的 2303/2304/2401 身份和 Flash 首次可操作状态。");
						BattleBridgeState ready = await _battleRunner.ConfirmEntryAsync(async () =>
						{
							var result = await _sender.SendAsync(request, token).ConfigureAwait(false);
							nextSendAt = clock.Elapsed.TotalMilliseconds + 200;
							return result;
						}, token, () => CheckConnection(connectionEpoch)).ConfigureAwait(false);
						attachedBattleEpoch = _state.Current.BattleEpoch; attachedRoute = ready.BattleId;
						continue;
					}
					bool battleCommand = request.ExtensionId == 13 &&
						int.TryParse(request.Command, out int command) && command >= 1401 && command <= 1410;
					if (battleCommand)
					{
						var current = _state.Current;
						if (current.Phase != AolaExecutionPhase.Active && current.Phase != AolaExecutionPhase.Ending)
							throw new InvalidOperationException("当前没有已确认的活动战斗。");
						if (attachedBattleEpoch == -1)
						{
							// 自动开关/退出不等待输入窗口；活动自动战斗可能没有手动窗口。
							BattleBridgeState ready;
							if (request.Command == "1409" || request.Command == "1404")
							{
								var result = await _bridge.GetStateAsync(token).ConfigureAwait(false);
								ready = result.Succeeded ? result.State : null;
							}
							else ready = await _battleRunner.ConfirmCurrentAsync(token).ConfigureAwait(false);
							if (ready == null || !ready.Active || ready.Ended || ready.BattleId != current.BattleId)
								throw new InvalidOperationException("无法确认当前 Flash 战斗身份。");
							attachedBattleEpoch = current.BattleEpoch; attachedRoute = current.BattleId;
						}
						if (current.BattleEpoch != attachedBattleEpoch || current.BattleId != attachedRoute)
							throw new InvalidOperationException("战斗身份已改变，停止后续操作。");
						var live = await _bridge.GetStateAsync(token).ConfigureAwait(false);
						if (!live.Succeeded || !live.State.Active || live.State.Ended || live.State.BattleId != attachedRoute)
							throw new InvalidOperationException("Flash 战斗已结束、身份已改变或桥读取失败。");
					}
					var sent = await _sender.SendAsync(request, token).ConfigureAwait(false);
					nextSendAt = clock.Elapsed.TotalMilliseconds + 200;
					if (sent.Status != AolaCommandSendStatus.SubmittedToFlash && sent.Status != AolaCommandSendStatus.ServerSucceeded)
						throw new InvalidOperationException("提交失败，停止后续指令且不重试：" + sent.Message);
					if (request.ExtensionId == 13 && request.Command == "1404") _state.MarkEnding();
					Publish("已提交给 Flash；尚未确认服务器执行。");
				}
				if (group + 1 < groupCount)
				{
					Publish(string.Format("本组结束，组间休息 {0}ms。", restMilliseconds));
					await Task.Delay(restMilliseconds, token).ConfigureAwait(false);
					// 组间休息本身定义下一组的间隔，不额外叠加组内 200ms。
					nextSendAt = clock.Elapsed.TotalMilliseconds;
				}
			}
			Publish("文本序列已完成；Flash 自动战斗保持原状态。");
		}
		finally { Interlocked.Exchange(ref _running, 0); }
	}
	private void CheckConnection(long epoch)
	{
		var current = _state.Current;
		if (current.SessionEpoch != epoch) throw new InvalidOperationException("执行期间游戏连接或捕获状态已失效。");
		if (!string.IsNullOrEmpty(current.Error)) throw new InvalidOperationException(current.Error);
	}
	private async Task WaitForEndAsync(long connectionEpoch, CancellationToken token)
	{
		var initial = _state.Current;
		long battleEpoch = initial.BattleEpoch;
		bool entering = initial.Phase == AolaExecutionPhase.Entering;
		while (true)
		{
			token.ThrowIfCancellationRequested();
			var current = _state.Read(out Task changed);
			CheckConnection(connectionEpoch);
			if (!current.Connected || current.Phase == AolaExecutionPhase.Unknown)
				throw new InvalidOperationException("无法确认当前连接或战斗状态；停止等待。");
			if (entering && current.Phase != AolaExecutionPhase.Entering)
			{ battleEpoch = current.BattleEpoch; entering = false; }
			if (!entering && current.BattleEpoch != battleEpoch)
				throw new InvalidOperationException("等待期间战斗身份已改变。");
			if (current.Phase == AolaExecutionPhase.Idle) return;
			await AolaExecutionState.AwaitChangeAsync(changed, token).ConfigureAwait(false);
		}
	}
}
