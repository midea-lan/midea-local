"""Midea Local library exceptions."""

from __future__ import annotations


class MideaLocalError(Exception):
    """Base class for mideal_local errors."""


class CannotAuthenticate(MideaLocalError):
    """Exception raised when credentials are incorrect."""


class CannotConnect(MideaLocalError):
    """Exception raised when connection fails."""


class DataUnexpectedLength(MideaLocalError):
    """Exception raised when data length is less or more than expected."""


class DataSignDoesntMatch(MideaLocalError):
    """Exception raised when data sign is not matching."""


class DataSignWrongType(MideaLocalError):
    """Exception raised when data is the wrong type to sign."""


class ElementMissing(MideaLocalError):
    """Exception raised when a element is missing."""


class MessageWrongFormat(MideaLocalError):
    """Exception raised when message format is wrong."""


class SocketException(MideaLocalError):
    """Exception raise by socket error."""


class ValueWrongType(MideaLocalError):
    """Exception raised when the value has a wrong data type."""


# Verified against mp-prod.appsmb.com. The wire message text varies by locale
# and endpoint (65027 comes back in Chinese), so callers should branch on the
# code; the meaning here is only for logging.
CLOUD_ERROR_MEANINGS: dict[int, str] = {
    3004: (
        "malformed or rejected request: bad udpid/applianceCodes, or the "
        "endpoint is disabled on this cloud"
    ),
    3102: "account or password incorrect",
    3144: "login session is no longer valid (empty loginId); log in again",
    3201: (
        "the account has no permission for this device; it is bound to a "
        "different account"
    ),
    7610: "too many failed login attempts; locked for about 5 minutes",
    9999: "generic or transient cloud error",
    65027: "maximum number of simultaneously logged-in devices exceeded",
}

# getToken / appliance endpoints answer with this when the authenticated account
# does not own the appliance it asked about (device paired under another
# account). See https://github.com/mill1000/midea-ac-py/issues/482.
NO_PERMISSION_CODES = frozenset({3201})

# Failures of the login / loginId step that a user has to act on (wrong
# credentials, expired session, rate limit, device-count limit).
LOGIN_ERROR_CODES = frozenset({3102, 3144, 7610, 65027})


class MideaCloudError(MideaLocalError):
    """Exception raised when a Midea cloud API request returns an error."""

    def __init__(self, code: int, message: str) -> None:
        """Initialize with the cloud error code and message."""
        meaning = CLOUD_ERROR_MEANINGS.get(code)
        detail = f"{message} ({meaning})" if meaning else message
        super().__init__(f"Cloud request failed with code {code}: {detail}")
        self.code = code
        self.message = message


class NoDeviceRegistered(MideaCloudError):
    """Exception raised when the account has no paired device for the request.

    The Midea cloud verifies device ownership before issuing a local token/key;
    an account that did not pair the appliance itself cannot retrieve them.
    See https://github.com/mill1000/midea-ac-py/issues/482.
    """


class CloudLoginError(MideaCloudError):
    """Exception raised when the cloud login / loginId step fails with a known code.

    Carries the cloud ``code`` so callers can map it to a specific message
    (wrong credentials, expired session, rate limit, too many logged-in
    devices); see ``LOGIN_ERROR_CODES`` and ``CLOUD_ERROR_MEANINGS``.
    """


def cloud_api_error(code: int, message: str) -> MideaCloudError:
    """Return the most specific MideaCloudError subclass for a cloud error code."""
    if code in NO_PERMISSION_CODES:
        return NoDeviceRegistered(code, message)
    if code in LOGIN_ERROR_CODES:
        return CloudLoginError(code, message)
    return MideaCloudError(code, message)
