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


# Maps a Midea cloud error code to a stable, user-actionable slug so callers can
# show a specific message without pattern-matching on the numeric code. The
# comment after each entry is the human explanation; the wire message text
# varies by locale and endpoint (65027 comes back in Chinese) so never match on
# it. Codes absent here -- and transient 9999 -- fall back to "cloud_error".
# Seen on mp-prod.appsmb.com and the Meiju gateway (1002 / 40404).
CLOUD_ERRORS: dict[int, str] = {
    1002: "cloud_error",  # missing or wrong-type request parameter
    3004: "cloud_error",  # malformed/rejected request, or endpoint disabled
    3101: "invalid_auth",  # account password is incorrect
    3102: "invalid_auth",  # account or password incorrect
    3106: "cloud_session_expired",  # login session is invalid; log in again
    3144: "cloud_session_expired",  # login session invalid (empty loginId)
    3201: "device_not_registered",  # device is bound to a different account
    3301: "invalid_cloud_server",  # invalid app key for this cloud
    7610: "account_locked",  # too many failed logins; ~5 minute lockout
    9999: "cloud_error",  # generic or transient cloud error
    40404: "cloud_error",  # the API endpoint was retired or moved
    65027: "too_many_logged_in_devices",  # too many simultaneous logins
}

# getToken / appliance endpoints answer with this when the authenticated account
# does not own the appliance it asked about (device paired under another
# account). See https://github.com/mill1000/midea-ac-py/issues/482.
NO_PERMISSION_CODES = frozenset({3201})

# Sporadic server-side failures that a plain resend usually clears: 9999
# "system error" comes back for otherwise valid login / getToken calls on both
# the legacy mapp.appsmb.com backend and the v5 proxy. midea-beautiful-air
# likewise treats 9999 as ignore-and-retry (see its ``handle_api_error``).
TRANSIENT_CLOUD_ERROR_CODES = frozenset({9999})

# Failures of the login / loginId step that a user has to act on (wrong
# credentials, invalid app key, expired session, rate limit, device-count
# limit). 3101/3102 wrong password/account, 3301 wrong app key, 3106/3144
# dead session -- all reported by nbogojevic/midea-beautiful-air.
LOGIN_ERROR_CODES = frozenset({3101, 3102, 3106, 3144, 3301, 7610, 65027})


class MideaCloudError(MideaLocalError):
    """Exception raised when a Midea cloud API request returns an error."""

    def __init__(self, code: int, message: str) -> None:
        """Initialize with the cloud error code and message."""
        super().__init__(f"Cloud request failed with code {code}: {message}")
        self.code = code
        self.message = message
        self.translation_key = CLOUD_ERRORS.get(code, "cloud_error")


class NoDeviceRegistered(MideaCloudError):
    """Exception raised when the account has no paired device for the request.

    The Midea cloud verifies device ownership before issuing a local token/key;
    an account that did not pair the appliance itself cannot retrieve them.
    See https://github.com/mill1000/midea-ac-py/issues/482.
    """


class CloudLoginError(MideaCloudError):
    """Exception raised when the cloud login / loginId step fails with a known code.

    Carries the cloud ``code`` and a ``translation_key`` so callers can map it
    to a specific message (wrong credentials, expired session, rate limit, too
    many logged-in devices); see ``LOGIN_ERROR_CODES`` and ``CLOUD_ERRORS``.
    """


def cloud_api_error(code: int, message: str) -> MideaCloudError:
    """Return the most specific MideaCloudError subclass for a cloud error code."""
    if code in NO_PERMISSION_CODES:
        return NoDeviceRegistered(code, message)
    if code in LOGIN_ERROR_CODES:
        return CloudLoginError(code, message)
    return MideaCloudError(code, message)
