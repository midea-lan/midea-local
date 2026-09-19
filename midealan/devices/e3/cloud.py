"""Midea E3 cloud usage report.

The E3 local protocol does not report water or gas consumption; those values
only exist in the Midea cloud, where the official app requests them with the
``dayReportV2`` message (see :meth:`MideaCloud.get_day_report`). This module
parses that report into an :class:`E3DayReport` and fetches it with an
:class:`E3CloudClient`.
"""

import asyncio
import logging
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from typing import Any

from aiohttp import ClientSession

from midealan.cloud import SUPPORTED_CLOUDS, MideaCloud, get_midea_cloud
from midealan.exceptions import CloudAuthError, CloudError

_LOGGER = logging.getLogger(__name__)

# The daily values are the newest entry of the month-to-date series the report
# carries: 31 days, or 7 on models that only report the last week.
DAILY_SERIES_LENGTH = 31
WEEK_SERIES_LENGTH = 7
MONTHLY_SERIES_LENGTH = 12
# A token issued by a fresh login is rejected for a couple of seconds until the
# gateway propagates it, so an auth failure is retried once after this delay.
AUTH_RETRY_DELAY = 3.0


class _LoginTokenRejected(CloudAuthError):
    """Raised when a token from a completed login is still rejected."""


@dataclass(frozen=True, slots=True)
class E3DayReport:
    """Parsed dayReportV2 data for an E3 gas water heater.

    ``*_daily`` is the most recent complete day, ``*_monthly`` the current
    month to date and ``*_last_month`` the previous calendar month. Water is in
    litres, gas in cubic metres and duration in minutes.
    """

    report_date: date
    water_daily: float | None
    gas_daily: float | None
    duration_daily: float | None
    water_monthly: float | None
    gas_monthly: float | None
    water_last_month: float | None
    gas_last_month: float | None


def parse_day_report(result: dict[str, Any]) -> E3DayReport:
    """Parse a dayReportV2 ``result`` payload.

    Returns
    -------
    E3DayReport
        The parsed usage values.

    """
    return E3DayReport(
        report_date=_parse_report_date(result.get("date")),
        water_daily=_parse_daily(result, "hotwaterUsem", "hotwaterUse7"),
        gas_daily=_parse_daily(result, "gasUsem", "gasUse7"),
        duration_daily=_parse_daily(result, "durTimem", "durTime7"),
        water_monthly=_parse_monthly(result, "hotwaterUsey")[0],
        gas_monthly=_parse_monthly(result, "gasUsey")[0],
        water_last_month=_parse_monthly(result, "hotwaterUsey")[1],
        gas_last_month=_parse_monthly(result, "gasUsey")[1],
    )


def _parse_series(value: object, length: int) -> tuple[float, ...]:
    """Parse a comma separated numeric series, keeping the newest entries.

    Returns
    -------
    tuple[float, ...]
        The newest ``length`` values, or an empty tuple when absent or invalid.

    """
    if not isinstance(value, str):
        return ()
    parts = value.split(",")
    if len(parts) < length:
        return ()
    try:
        return tuple(float(part) for part in parts[-length:])
    except ValueError:
        return ()


def _parse_daily(
    result: dict[str, Any],
    monthly_key: str,
    weekly_key: str,
) -> float | None:
    """Return the newest value of a daily series.

    Falls back to the 7 day series of models that do not report the full month.

    Returns
    -------
    float | None
        The most recent value, or None when the report carries no series.

    """
    series = _parse_series(result.get(monthly_key), DAILY_SERIES_LENGTH)
    if not series:
        series = _parse_series(result.get(weekly_key), WEEK_SERIES_LENGTH)
    return series[-1] if series else None


def _parse_monthly(
    result: dict[str, Any],
    key: str,
) -> tuple[float | None, float | None]:
    """Return the current and previous value of a monthly series.

    Returns
    -------
    tuple[float | None, float | None]
        The current month to date and the previous calendar month.

    """
    series = _parse_series(result.get(key), MONTHLY_SERIES_LENGTH)
    if not series:
        return (None, None)
    return (series[-1], series[-2] if len(series) > 1 else None)


def _parse_report_date(value: object) -> date:
    """Parse the report date, falling back to yesterday in local time.

    Returns
    -------
    date
        The date the report describes.

    """
    if isinstance(value, str):
        try:
            return date.fromisoformat(value)
        except ValueError:
            pass
    # Yesterday in local time: the report describes the user's day.
    return datetime.now(tz=UTC).astimezone().date() - timedelta(days=1)


class E3CloudClient:
    """Fetch the Midea cloud usage report of E3 appliances.

    Either an ``access_token`` (used as is) or an ``account``/``password`` pair
    (used to log in and refresh the token when it expires) must be provided.
    The report is written once a day by the cloud.
    """

    def __init__(
        self,
        cloud_name: str,
        session: ClientSession,
        *,
        access_token: str = "",
        account: str = "",
        password: str = "",
    ) -> None:
        """Initialize the E3 cloud report client."""
        if cloud_name not in SUPPORTED_CLOUDS:
            msg = f"Unsupported cloud: {cloud_name}"
            raise CloudError(msg)
        self._cloud_name = cloud_name
        self._session = session
        self._access_token = access_token
        self._account = account
        self._password = password
        self._cloud: MideaCloud | None = None

    async def async_get_report(self, appliance_id: int) -> E3DayReport | None:
        """Fetch and parse the usage report of an appliance.

        Returns
        -------
        E3DayReport | None
            The parsed report, or None when the cloud holds no report for the
            appliance yet.

        Raises
        ------
        CloudAuthError
            If no credentials are stored or the cloud rejected them.
        CloudError
            If the cloud could not be reached or answered with an error.

        """
        try:
            result = await self._async_fetch(appliance_id)
        except _LoginTokenRejected:
            # A fresh token can be rejected until the gateway propagates it;
            # drop the cached client and authenticate again.
            self._cloud = None
            result = await self._async_fetch(appliance_id)
        return None if result is None else parse_day_report(result)

    async def _async_fetch(self, appliance_id: int) -> dict[str, Any] | None:
        """Fetch the raw report, logging in again when the token was rejected.

        Returns
        -------
        dict[str, Any] | None
            The raw report result, or None when the cloud holds no report.

        """
        cloud = await self._async_cloud()
        if self._access_token:
            # The stored token is used as is; the account, when there is one,
            # only logs in after the token was rejected.
            try:
                return await cloud.get_day_report(appliance_id)
            except CloudAuthError:
                if not self._has_login():
                    # A freshly stored token can need a moment to become valid
                    # server side; retry the same token once after a delay.
                    await asyncio.sleep(AUTH_RETRY_DELAY)
                    return await cloud.get_day_report(appliance_id)
                _LOGGER.debug(
                    "Stored Midea cloud token was rejected for appliance %s, "
                    "logging in again",
                    appliance_id,
                )
                # From here on the account's token replaces the stored one.
                self._access_token = ""
                self._cloud = None
                cloud = await self._async_cloud()
        try:
            return await cloud.get_day_report(appliance_id)
        except CloudAuthError:
            # A token issued by a fresh login is rejected until the gateway
            # propagates it; retry the same token once after a short delay.
            await asyncio.sleep(AUTH_RETRY_DELAY)
            try:
                return await cloud.get_day_report(appliance_id)
            except CloudAuthError as retry_err:
                raise _LoginTokenRejected(str(retry_err)) from retry_err

    async def _async_cloud(self) -> MideaCloud:
        """Return the cloud client, creating it on first use.

        The client is authenticated with the stored access token, or by logging
        in with the stored account when no token is available.

        Returns
        -------
        MideaCloud
            The authenticated cloud client.

        """
        if self._cloud is None:
            if self._access_token:
                cloud = self._new_cloud()
                cloud.set_access_token(self._access_token)
                self._cloud = cloud
            else:
                self._cloud = await self._async_login_cloud()
        return self._cloud

    async def _async_login_cloud(self) -> MideaCloud:
        """Create a cloud client logged in with the stored account.

        Returns
        -------
        MideaCloud
            The logged in cloud client.

        Raises
        ------
        CloudAuthError
            If no account is stored or the login failed.

        """
        if not self._has_login():
            msg = "No Midea cloud access token or account stored"
            raise CloudAuthError(msg)
        cloud = self._new_cloud()
        if not await cloud.login():
            msg = "Midea cloud login failed"
            raise CloudAuthError(msg)
        return cloud

    def _new_cloud(self) -> MideaCloud:
        """Create a cloud client for the configured cloud."""
        return get_midea_cloud(
            self._cloud_name,
            self._session,
            self._account,
            self._password,
        )

    def _has_login(self) -> bool:
        """Whether account credentials allow a re-login."""
        return bool(self._account and self._password)
