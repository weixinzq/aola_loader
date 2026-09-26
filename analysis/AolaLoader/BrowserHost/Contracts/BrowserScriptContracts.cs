// 架构角色：定义浏览器脚本执行请求、结果和失败分类，不依赖具体 CefSharp 类型。
// 数据流：BrowserHost 调用者 <-> IBrowserSession 实现之间的稳定 DTO 契约。
using System;
using Newtonsoft.Json.Linq;

namespace AolaLoader.BrowserHost.Contracts;

internal sealed class BrowserScriptRequest
{
	public BrowserScriptRequest(string operationName, string script, TimeSpan timeout)
	{
		if (!BrowserContractValidation.IsStableName(operationName))
		{
			throw new ArgumentException("Script operation name is invalid.", nameof(operationName));
		}
		if (string.IsNullOrWhiteSpace(script))
		{
			throw new ArgumentException("Script is required.", nameof(script));
		}
		if (timeout <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(timeout));
		}

		OperationName = operationName;
		Script = script;
		Timeout = timeout;
	}

	public string OperationName { get; }

	public string Script { get; }

	public TimeSpan Timeout { get; }
}

internal enum BrowserScriptFailureKind
{
	None,
	PageNotReady,
	BrowserClosed,
	ExecutionFailed,
	Timeout,
	Cancelled
}

internal sealed class BrowserScriptResult
{
	private readonly JToken _value;

	private BrowserScriptResult(
		bool succeeded,
		JToken value,
		BrowserScriptFailureKind failureKind,
		string message)
	{
		Succeeded = succeeded;
		_value = value?.DeepClone();
		FailureKind = failureKind;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }

	public JToken Value => _value?.DeepClone();

	public BrowserScriptFailureKind FailureKind { get; }

	public string Message { get; }

	public static BrowserScriptResult Success(JToken value)
	{
		return new BrowserScriptResult(true, value, BrowserScriptFailureKind.None, null);
	}

	public static BrowserScriptResult Failure(BrowserScriptFailureKind failureKind, string message)
	{
		if (failureKind == BrowserScriptFailureKind.None)
		{
			throw new ArgumentOutOfRangeException(nameof(failureKind));
		}
		return new BrowserScriptResult(false, null, failureKind, message);
	}
}

