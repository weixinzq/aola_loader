// 架构角色：生产主动发送实现，只经 IPageBridge 复用当前 Flash 原连接，不创建旁路 socket。
// 数据流：AolaSendRequest -> 参数校验/扩展映射 -> 页面桥 -> 分阶段 AolaCommandSendUpdate。
using System;
using System.Threading;
using System.Threading.Tasks;
using AolaLoader.BrowserHost.Contracts;
using AolaSocketHack.Contracts;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace AolaLoader.Features.ActiveSend;

internal sealed class AolaFlashCommandSender : IAolaCommandSender
{
	private static readonly TimeSpan SubmissionTimeout = TimeSpan.FromSeconds(5);
	private readonly IPageBridge _pageBridge;

	public AolaFlashCommandSender(IPageBridge pageBridge)
	{
		_pageBridge = pageBridge ?? throw new ArgumentNullException(nameof(pageBridge));
	}

	public event Action<AolaCommandSendUpdate> StatusChanged;

	public async Task<AolaCommandSendUpdate> SendAsync(
		AolaSendRequest request,
		CancellationToken cancellationToken)
	{
		if (request == null)
		{
			throw new ArgumentNullException(nameof(request));
		}
		string requestId = Guid.NewGuid().ToString("N");
		request.RequestId = requestId;
		if (!AolaExtensionMap.TryGetName(request.ExtensionId, out string extensionName))
		{
			return Publish(request, AolaCommandSendStatus.SubmissionFailed,
				"拒绝发送：当前客户端证据中没有扩展 ID " + request.ExtensionId + " 的名称映射。");
		}

		JObject parameters;
		try
		{
			parameters = JObject.Parse(request.ParametersJson ?? "{}");
			parameters.Remove(":ext_seq;");
		}
		catch (JsonException ex)
		{
			return Publish(request, AolaCommandSendStatus.SubmissionFailed,
				"拒绝发送：param 不是 JSON 对象：" + ex.Message);
		}
		if (cancellationToken.IsCancellationRequested)
		{
			return Publish(request, AolaCommandSendStatus.SubmissionFailed, "发送已取消，未提交给 Flash。");
		}

		JObject submitArguments = new JObject
		{
			["requestId"] = requestId,
			["extension"] = extensionName,
			["command"] = request.Command,
			["parametersJson"] = parameters.ToString(Formatting.None)
		};
		string operation = "activeSend.submit";
		if (request.ExtensionId == 13 && request.Command == "1409")
		{
			if (parameters.Count != 1 || parameters["useAiType"]?.Type != JTokenType.Integer ||
				(parameters.Value<int>("useAiType") != 0 && parameters.Value<int>("useAiType") != 1))
				return Publish(request, AolaCommandSendStatus.SubmissionFailed, "1409 只接受 useAiType=0 或 1。");
			operation = "battle.auto";
			submitArguments = new JObject { ["enabled"] = parameters.Value<int>("useAiType") == 1 };
		}
		PageBridgeResult submitted = await _pageBridge.InvokeAsync(
			new PageBridgeRequest(operation, submitArguments, SubmissionTimeout),
			cancellationToken).ConfigureAwait(false);
		if (!submitted.Succeeded)
		{
			AolaCommandSendStatus status = submitted.FailureKind == PageBridgeFailureKind.Timeout
				? AolaCommandSendStatus.TimedOut
				: AolaCommandSendStatus.SubmissionFailed;
			return Publish(request, status, submitted.Message);
		}
		if (!TryReadStatus(submitted.Value, out AolaCommandSendStatus submittedStatus, out string submittedCode))
		{
			return Publish(request, AolaCommandSendStatus.SubmissionFailed,
				"Flash 未返回 SubmittedToFlash，发送已停止。" + FormatCode(submittedCode));
		}

		AolaCommandSendUpdate submittedUpdate = Publish(request, AolaCommandSendStatus.SubmittedToFlash,
			string.Format("已提交给 Flash 原连接：ext={0} ({1}), cmd={2}",
				request.ExtensionId, extensionName, request.Command));
		if (submittedStatus == AolaCommandSendStatus.ServerSucceeded ||
			submittedStatus == AolaCommandSendStatus.ServerRejected)
		{
			return PublishServerResult(request, submittedStatus, submittedCode);
		}
		return submittedUpdate;
	}

	private AolaCommandSendUpdate Publish(
		AolaSendRequest request,
		AolaCommandSendStatus status,
		string message)
	{
		AolaCommandSendUpdate update = new AolaCommandSendUpdate(
			request.RequestId,
			request.ExtensionId,
			request.Command,
			status,
			message);
		Action<AolaCommandSendUpdate> handlers = StatusChanged;
		if (handlers != null)
		{
			foreach (Action<AolaCommandSendUpdate> handler in handlers.GetInvocationList())
			{
				try
				{
					handler(update);
				}
				catch
				{
				}
			}
		}
		return update;
	}

	private AolaCommandSendUpdate PublishServerResult(
		AolaSendRequest request,
		AolaCommandSendStatus status,
		string code)
	{
		return status == AolaCommandSendStatus.ServerSucceeded
			? Publish(request, status, "服务器已明确回调成功。" + FormatCode(code))
			: Publish(request, AolaCommandSendStatus.ServerRejected,
				"服务器已明确拒绝该命令。" + FormatCode(code));
	}

	private static bool TryReadStatus(
		JToken value,
		out AolaCommandSendStatus status,
		out string code)
	{
		status = AolaCommandSendStatus.SubmissionFailed;
		code = value?.Value<string>("code") ?? string.Empty;
		string name = value?.Value<string>("status");
		return Enum.TryParse(name, false, out status) &&
			(status == AolaCommandSendStatus.SubmittedToFlash ||
			 status == AolaCommandSendStatus.ServerSucceeded ||
			 status == AolaCommandSendStatus.ServerRejected);
	}

	private static string FormatCode(string code)
	{
		return string.IsNullOrWhiteSpace(code) ? string.Empty : " 结果码=" + code;
	}
}
