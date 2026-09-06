"""Public error hierarchy for the offline client."""


class AolaOfflineError(Exception):
    """Base class for expected client failures."""


class ConfigError(AolaOfflineError):
    """The local account configuration is missing or invalid."""


class AuthenticationError(AolaOfflineError):
    """The HTTP account login failed or returned unusable data."""


class ConnectionFailed(AolaOfflineError):
    """A game transport could not be established or logged in."""


class ProtocolError(AolaOfflineError):
    """A frame or protocol value violates the supported contract."""


class DisconnectedError(AolaOfflineError):
    """The game connection closed while an operation was pending."""


class ReceiveTimeout(AolaOfflineError):
    """A subscription did not receive a matching message in time."""


class SubscriptionOverflow(AolaOfflineError):
    """A subscriber could not keep up with the receive stream."""


class ScriptLoadError(AolaOfflineError):
    """A trusted local script does not satisfy the script contract."""

