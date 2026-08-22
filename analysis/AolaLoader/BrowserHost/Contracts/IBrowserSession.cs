using System;
using System.Threading;
using System.Threading.Tasks;

namespace AolaLoader.BrowserHost.Contracts;

internal interface IBrowserSession : IDisposable
{
	string CurrentAddress { get; }

	bool IsClosed { get; }

	event Action<BrowserPageLifecycleEvent> PageLifecycleChanged;

	void Navigate(string address);

	void Refresh(BrowserRefreshMode mode);

	Task<BrowserScriptResult> ExecuteScriptAsync(
		BrowserScriptRequest request,
		CancellationToken cancellationToken);
}

internal enum BrowserRefreshMode
{
	Normal,
	IgnoreCache
}

internal enum BrowserPageLifecycleKind
{
	NavigationStarted,
	MainFrameReady,
	NavigationFailed,
	Closed
}

internal sealed class BrowserPageLifecycleEvent
{
	public BrowserPageLifecycleEvent(
		BrowserPageLifecycleKind kind,
		string address,
		DateTime timestampUtc,
		string error = null)
	{
		if (timestampUtc.Kind != DateTimeKind.Utc)
		{
			throw new ArgumentException("Lifecycle timestamp must be UTC.", nameof(timestampUtc));
		}
		if (kind != BrowserPageLifecycleKind.Closed &&
			!BrowserContractValidation.TryCreateHttpUri(address, out _))
		{
			throw new ArgumentException("Lifecycle address must be an absolute HTTP or HTTPS URL.", nameof(address));
		}

		Kind = kind;
		Address = address ?? string.Empty;
		TimestampUtc = timestampUtc;
		Error = error ?? string.Empty;
	}

	public BrowserPageLifecycleKind Kind { get; }

	public string Address { get; }

	public DateTime TimestampUtc { get; }

	public string Error { get; }
}

internal static class BrowserContractValidation
{
	public static bool TryCreateHttpUri(string value, out Uri uri)
	{
		return Uri.TryCreate(value, UriKind.Absolute, out uri) &&
			(uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) &&
			!string.IsNullOrWhiteSpace(uri.Host);
	}

	public static bool IsStableName(string value)
	{
		if (string.IsNullOrWhiteSpace(value) || value.Length > 128)
		{
			return false;
		}
		for (int index = 0; index < value.Length; index++)
		{
			char current = value[index];
			if (!(char.IsLetterOrDigit(current) || current == '.' || current == '_' || current == '-'))
			{
				return false;
			}
		}
		return true;
	}
}

