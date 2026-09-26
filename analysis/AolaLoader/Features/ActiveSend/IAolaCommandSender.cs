// 架构角色：定义功能模块使用的主动发送端口及提交阶段语义，隐藏页面桥实现。
// 数据流：Feature 提交请求；实现以进度回调和最终状态返回 Page/Flash 提交结果。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaSocketHack.Contracts;

namespace AolaLoader.Features.ActiveSend;

internal interface IAolaCommandSender
{
	event Action<AolaCommandSendUpdate> StatusChanged;

	Task<AolaCommandSendUpdate> SendAsync(
		AolaSendRequest request,
		CancellationToken cancellationToken);
}

internal enum AolaCommandSendStatus
{
	SubmissionFailed,
	SubmittedToFlash,
	ServerSucceeded,
	ServerRejected,
	TimedOut
}

internal sealed class AolaCommandSendUpdate
{
	public AolaCommandSendUpdate(
		string requestId,
		int extensionId,
		string command,
		AolaCommandSendStatus status,
		string message)
	{
		RequestId = requestId ?? string.Empty;
		ExtensionId = extensionId;
		Command = command ?? string.Empty;
		Status = status;
		Message = message ?? string.Empty;
	}

	public string RequestId { get; }

	public int ExtensionId { get; }

	public string Command { get; }

	public AolaCommandSendStatus Status { get; }

	public string Message { get; }
}
