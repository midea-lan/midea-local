"""Test cloud"""

import os
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, Mock

from midealocal.cloud import MSmartHomeCloud, MeijuCloud, MideaAirCloud, get_midea_cloud


class CloudTest(IsolatedAsyncioTestCase):
    """Cloud test case."""

    responses: dict[str, bytes] = {}

    def setUp(self) -> None:
        """Set tests up."""
        for file in os.listdir(os.path.join(os.path.dirname(__file__), "responses")):
            filename = os.path.basename(file)
            with open(
                file=os.path.join(os.path.dirname(__file__), "responses", file),
                encoding="utf-8",
            ) as f:
                self.responses[filename] = bytes(f.read(), encoding="utf-8")

    def test_get_midea_cloud(self) -> None:
        """Test get midea cloud"""
        assert isinstance(get_midea_cloud("美的美居", None, "", ""), MeijuCloud)
        assert isinstance(get_midea_cloud("MSmartHome", None, "", ""), MSmartHomeCloud)
        assert isinstance(get_midea_cloud("Midea Air", None, "", ""), MideaAirCloud)
        assert isinstance(get_midea_cloud("NetHome Plus", None, "", ""), MideaAirCloud)
        assert isinstance(get_midea_cloud("Ariston Clima", None, "", ""), MideaAirCloud)

    async def test_meijucloud_login_success(self) -> None:
        """Test MeijuCloud login"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_login_id.json"],
                self.responses["meijucloud_login.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        assert await cloud.login()

    async def test_meijucloud_login_invalid_user(self) -> None:
        """Test MeijuCloud login invalid user"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(return_value=self.responses["invalid_response.json"])
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        assert not await cloud.login()

    async def test_meijucloud_get_keys(self) -> None:
        """Test MeijuCloud get_keys"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["meijucloud_get_keys.json"]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        keys: dict = await cloud.get_keys(100)
        assert keys.get(1).get("token") == "returnedappliancetoken"
        assert keys.get(1).get("key") == "returnedappliancekey"

    async def test_meijucloud_list_home(self) -> None:
        """Test MeijuCloud list_home"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["meijucloud_list_home.json"]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        homes = await cloud.list_home()
        assert len(homes.keys()) == 2
        assert homes.get(1) == "Home 1"
        assert homes.get(2) == "Home 2"
