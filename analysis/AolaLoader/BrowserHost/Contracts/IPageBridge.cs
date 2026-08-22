using System;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace AolaLoader.BrowserHost.Contracts;

internal interface IPageBridge : IDisposable
{
	PageBridgeAvailability Availability { get; }

	Task<PageBridgeResult> InvokeAsync(
		PageBridgeRequest request,
		CancellationToken cancellationToken);

	Task<PageBridgeResult> PushFeatureStateAsync(
		PageFeatureStatePush state,
		CancellationToken cancellationToken);
}

internal enum PageBridgeAvailability
{
	Unknown,
	PageNotReady,
	BridgeNotInstalled,
	Ready,
	Closed
}

internal enum PageBridgeFailureKind
{
	None,
	BridgeNotInstalled,
	PageNotReady,
	InvocationFailed,
	Timeout,
	BrowserClosed,
	Cancelled
}

internal sealed class PageBridgeRequest
{
	private readonly JObject _arguments;

	public PageBridgeRequest(string operation, JObject arguments, TimeSpan timeout)
	{
		if (!BrowserContractValidation.IsStableName(operation))
		{
			throw new ArgumentException("Bridge operation name is invalid.", nameof(operation));
		}
		if (timeout <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(timeout));
		}
		Operation = operation;
		_arguments = arguments == null ? new JObject() : (JObject)arguments.DeepClone();
		Timeout = timeout;
	}

	public string Operation { get; }

	public JObject Arguments => (JObject)_arguments.DeepClone();

	public TimeSpan Timeout { get; }
}

internal sealed class PageFeatureStatePush
{
	private readonly JObject _state;

	public PageFeatureStatePush(string featureName, long revision, JObject state, TimeSpan timeout)
	{
		if (!BrowserContractValidation.IsStableName(featureName))
		{
			throw new ArgumentException("Feature name is invalid.", nameof(featureName));
		}
		if (revision < 0)
		{
			throw new ArgumentOutOfRangeException(nameof(revision));
		}
		if (timeout <= TimeSpan.Zero)
		{
			throw new ArgumentOutOfRangeException(nameof(timeout));
		}
		FeatureName = featureName;
		Revision = revision;
		_state = state == null ? new JObject() : (JObject)state.DeepClone();
		Timeout = timeout;
	}

	public string FeatureName { get; }

	public long Revision { get; }

	public JObject State => (JObject)_state.DeepClone();

	public TimeSpan Timeout { get; }
}

internal sealed class PageBridgeResult
{
	private readonly JToken _value;

	private PageBridgeResult(
		bool succeeded,
		JToken value,
		PageBridgeFailureKind failureKind,
		string message)
	{
		Succeeded = succeeded;
		_value = value?.DeepClone();
		FailureKind = failureKind;
		Message = message ?? string.Empty;
	}

	public bool Succeeded { get; }

	public JToken Value => _value?.DeepClone();

	public PageBridgeFailureKind FailureKind { get; }

	public string Message { get; }

	public static PageBridgeResult Success(JToken value)
	{
		return new PageBridgeResult(true, value, PageBridgeFailureKind.None, null);
	}

	public static PageBridgeResult Failure(PageBridgeFailureKind failureKind, string message)
	{
		if (failureKind == PageBridgeFailureKind.None)
		{
			throw new ArgumentOutOfRangeException(nameof(failureKind));
		}
		return new PageBridgeResult(false, null, failureKind, message);
	}
}

