"""Test E3 cloud report."""

from datetime import UTC, date, datetime
from typing import Any
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, Mock, patch

import pytest

from midealan.devices.e3.cloud import (
    E3CloudClient,
    parse_day_report,
)
from midealan.exceptions import CloudAuthError, CloudError

DAILY_SERIES = ",".join(str(value) for value in range(1, 32))
WEEK_SERIES = ",".join(str(value) for value in range(25, 32))
MONTHLY_SERIES = ",".join(str(value) for value in range(1, 13))


def _result(**overrides: object) -> dict[str, Any]:
    """Build a dayReportV2 result payload with all series present."""
    result: dict[str, Any] = {
        "date": "2026-09-10",
        "hotwaterUsem": DAILY_SERIES,
        "gasUsem": DAILY_SERIES,
        "durTimem": DAILY_SERIES,
        "hotwaterUsey": MONTHLY_SERIES,
        "gasUsey": MONTHLY_SERIES,
    }
    result.update(overrides)
    return result


class TestParseDayReport:
    """Test parse_day_report."""

    def test_parse_day_report(self) -> None:
        """Parse the daily, monthly and previous month values."""
        report = parse_day_report(_result())
        assert report.report_date == date(2026, 9, 10)
        assert report.water_daily == 31
        assert report.gas_daily == 31
        assert report.duration_daily == 31
        assert report.water_monthly == 12
        assert report.gas_monthly == 12
        assert report.water_last_month == 11
        assert report.gas_last_month == 11

    def test_parse_day_report_weekly_fallback(self) -> None:
        """Use the 7 day series when the 31 day one is missing."""
        report = parse_day_report(
            _result(
                hotwaterUsem=None,
                hotwaterUse7=WEEK_SERIES,
                gasUsem="",
                gasUse7=WEEK_SERIES,
                durTimem="1,2",
                durTime7=None,
            ),
        )
        assert report.water_daily == 31
        assert report.gas_daily == 31
        assert report.duration_daily is None

    def test_parse_day_report_missing_series(self) -> None:
        """Report all values as None when the payload carries no series."""
        report = parse_day_report({})
        assert report.water_daily is None
        assert report.gas_daily is None
        assert report.duration_daily is None
        assert report.water_monthly is None
        assert report.gas_monthly is None
        assert report.water_last_month is None
        assert report.gas_last_month is None

    def test_parse_day_report_short_monthly_series(self) -> None:
        """Ignore a monthly series that does not cover 12 months."""
        report = parse_day_report(_result(hotwaterUsey="1,2,3"))
        assert report.water_monthly is None
        assert report.water_last_month is None

    def test_parse_day_report_invalid_numeric_series(self) -> None:
        """Ignore a daily series containing a non-numeric value."""
        invalid_series = ",".join(["1"] * 30 + ["invalid"])
        report = parse_day_report(_result(hotwaterUsem=invalid_series))
        assert report.water_daily is None

    def test_parse_day_report_invalid_date(self) -> None:
        """Fall back to yesterday in local time when the date is invalid."""
        fake_now = Mock()
        fake_now.astimezone.return_value = datetime(2026, 9, 12, 12, 0, tzinfo=UTC)
        with patch("midealan.devices.e3.cloud.datetime") as mock_datetime:
            mock_datetime.now.return_value = fake_now
            report = parse_day_report({"date": "not-a-date"})
        assert report.report_date == date(2026, 9, 11)


class E3CloudClientTest(IsolatedAsyncioTestCase):
    """Test the E3 cloud report client."""

    async def test_uses_stored_token(self) -> None:
        """Use the stored access token as is, without logging in."""
        cloud = Mock()
        cloud.get_day_report = AsyncMock(return_value=_result())
        session = Mock()
        client = E3CloudClient("美的美居", session, access_token="token")
        with patch(
            "midealan.devices.e3.cloud.get_midea_cloud",
            return_value=cloud,
        ) as get_cloud:
            report = await client.async_get_report(100)
        get_cloud.assert_called_once_with("美的美居", session, "", "")
        cloud.set_access_token.assert_called_once_with("token")
        cloud.login.assert_not_called()
        cloud.get_day_report.assert_awaited_once_with(100)
        assert report is not None
        assert report.water_daily == 31

    async def test_retries_stored_token(self) -> None:
        """Retry the stored token once when no account can log in."""
        cloud = Mock()
        cloud.get_day_report = AsyncMock(
            side_effect=[CloudAuthError("40002"), _result()],
        )
        client = E3CloudClient("美的美居", Mock(), access_token="token")
        with (
            patch(
                "midealan.devices.e3.cloud.get_midea_cloud",
                return_value=cloud,
            ),
            patch("asyncio.sleep", AsyncMock()) as sleep,
        ):
            report = await client.async_get_report(100)
        sleep.assert_awaited_once()
        assert cloud.get_day_report.await_count == 2
        assert report is not None

    async def test_rejected_stored_token_without_account_raises_after_retry(
        self,
    ) -> None:
        """Do not perform an outer retry when a standalone token is rejected."""
        cloud = Mock()
        cloud.get_day_report = AsyncMock(side_effect=CloudAuthError("40002"))
        client = E3CloudClient("美的美居", Mock(), access_token="token")
        with (
            patch(
                "midealan.devices.e3.cloud.get_midea_cloud",
                return_value=cloud,
            ),
            patch("asyncio.sleep", AsyncMock()) as sleep,
            pytest.raises(CloudAuthError),
        ):
            await client.async_get_report(100)
        sleep.assert_awaited_once()
        assert cloud.get_day_report.await_count == 2

    async def test_logs_in_after_rejected_token(self) -> None:
        """Log in with the stored account when the stored token was rejected."""
        token_cloud = Mock()
        token_cloud.get_day_report = AsyncMock(
            side_effect=CloudAuthError("40002"),
        )
        login_cloud = Mock()
        login_cloud.login = AsyncMock(return_value=True)
        login_cloud.get_day_report = AsyncMock(return_value=_result())
        client = E3CloudClient(
            "美的美居",
            Mock(),
            access_token="token",
            account="user",
            password="password",
        )
        with patch(
            "midealan.devices.e3.cloud.get_midea_cloud",
            side_effect=[token_cloud, login_cloud],
        ):
            report = await client.async_get_report(100)
        token_cloud.set_access_token.assert_called_once_with("token")
        token_cloud.login.assert_not_called()
        login_cloud.set_access_token.assert_not_called()
        login_cloud.login.assert_awaited_once()
        assert report is not None

    async def test_logs_in_without_token(self) -> None:
        """Log in with the stored account when no token is stored."""
        cloud = Mock()
        cloud.login = AsyncMock(return_value=True)
        cloud.get_day_report = AsyncMock(return_value=_result())
        client = E3CloudClient(
            "美的美居",
            Mock(),
            account="user",
            password="password",
        )
        with patch(
            "midealan.devices.e3.cloud.get_midea_cloud",
            return_value=cloud,
        ):
            report = await client.async_get_report(100)
            cached_report = await client.async_get_report(101)
        cloud.login.assert_awaited_once()
        assert cloud.get_day_report.await_count == 2
        assert report is not None
        assert cached_report is not None

    async def test_reauthenticates_when_fresh_token_is_rejected(self) -> None:
        """Log in again when even a fresh login token was rejected."""
        first = Mock()
        first.login = AsyncMock(return_value=True)
        first.get_day_report = AsyncMock(side_effect=CloudAuthError("40002"))
        second = Mock()
        second.login = AsyncMock(return_value=True)
        second.get_day_report = AsyncMock(return_value=_result())
        client = E3CloudClient(
            "美的美居",
            Mock(),
            account="user",
            password="password",
        )
        with (
            patch(
                "midealan.devices.e3.cloud.get_midea_cloud",
                side_effect=[first, second],
            ),
            patch("asyncio.sleep", AsyncMock()),
        ):
            report = await client.async_get_report(100)
        first.login.assert_awaited_once()
        assert first.get_day_report.await_count == 2
        second.login.assert_awaited_once()
        assert report is not None

    async def test_login_failure(self) -> None:
        """Raise CloudAuthError when the account login fails."""
        cloud = Mock()
        cloud.login = AsyncMock(return_value=False)
        client = E3CloudClient(
            "美的美居",
            Mock(),
            account="user",
            password="password",
        )
        with (
            patch(
                "midealan.devices.e3.cloud.get_midea_cloud",
                return_value=cloud,
            ),
            pytest.raises(CloudAuthError),
        ):
            await client.async_get_report(100)
        cloud.login.assert_awaited_once()

    async def test_no_credentials(self) -> None:
        """Raise CloudAuthError when neither token nor account is stored."""
        client = E3CloudClient("美的美居", Mock())
        with (
            patch(
                "midealan.devices.e3.cloud.get_midea_cloud",
            ) as get_cloud,
            pytest.raises(CloudAuthError),
        ):
            await client.async_get_report(100)
        get_cloud.assert_not_called()

    def test_unsupported_cloud(self) -> None:
        """Reject a cloud that does not provide usage reports."""
        with pytest.raises(CloudError):
            E3CloudClient("Invalid", Mock())
