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
        assert cloud is not None
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
        assert cloud is not None
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
        assert cloud is not None
        keys: dict = await cloud.get_keys(100)
        assert keys[1]["token"] == "returnedappliancetoken"
        assert keys[1]["key"] == "returnedappliancekey"

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
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 2
        assert homes[1] == "Home 1"
        assert homes[2] == "Home 2"

    async def test_meijucloud_list_appliances(self) -> None:
        """Test MeijuCloud list_appliances"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_list_appliances.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(1)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        assert appliances[1]["name"] == "Appliance Name"
        assert appliances[1]["type"] == 0xAC
        assert appliances[1]["sn"] == "mySecretKey"
        assert appliances[1]["sn8"] == "9d52c159"
        assert appliances[1]["model_number"] == 10
        assert appliances[1]["manufacturer_code"] == "1234"
        assert appliances[1]["model"] == "Product Model"
        assert appliances[1]["online"]

        assert appliances[2]["name"] == "Appliance Name 2"
        assert appliances[2]["type"] == 0xAC
        assert appliances[2]["sn"] == ""
        assert appliances[2]["sn8"] == "00000000"
        assert appliances[2]["model_number"] == 10
        assert appliances[2]["manufacturer_code"] == "1234"
        assert appliances[2]["model"] == "00000000"
        assert not appliances[2]["online"]

    async def test_meijucloud_get_device_info(self) -> None:
        """Test MeijuCloud get_device_info"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_get_device_info.json"],
                self.responses["meijucloud_get_device_info_alt.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device["name"] == "Appliance Name"
        assert device["type"] == 0xAC
        assert device["sn"] == "mySecretKey"
        assert device["sn8"] == "9d52c159"
        assert device["model_number"] == 10
        assert device["manufacturer_code"] == "1234"
        assert device["model"] == "Product Model"
        assert device["online"]

        device = await cloud.get_device_info(2)
        assert device["name"] == "Appliance Name 2"
        assert device["type"] == 0xAC
        assert device["sn"] == ""
        assert device["sn8"] == "00000000"
        assert device["model_number"] == 10
        assert device["manufacturer_code"] == "1234"
        assert device["model"] == "00000000"
        assert not device["online"]

    async def test_meijucloud_download_lua(self) -> None:
        """Test MeijuCloud download_lua"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["meijucloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
                self.responses["meijucloud_download_lua.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="9d52c159dcdd32bac5109cf54080fca7")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()

        if not os.path.exists("/tmp/download"):
            os.mkdir("/tmp/download")
        file = await cloud.download_lua("/tmp/download", 10, "00000000", "0xAC", "0010")
        assert file is not None
        assert os.path.exists(file)
        os.remove(file)
        os.removedirs("/tmp/download")

        res.status = 404
        assert (
            await cloud.download_lua("/tmp/download", 10, "00000000", "0xAC", "0010")
            is None
        )

    async def test_msmartcloud_login_success(self) -> None:
        """Test MSmartCloud login"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["msmartcloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_msmartcloud_login_invalid_user(self) -> None:
        """Test MSmartCloud login invalid user"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(return_value=self.responses["invalid_response.json"])
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_msmartcloud_list_home(self) -> None:
        """Test MSmartCloud list_home"""
        session = Mock()
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 1

    async def test_msmartcloud_list_appliances(self) -> None:
        """Test MSmartCloud list_appliances"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["msmartcloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
                self.responses["invalid_response.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(1)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        assert appliances[1]["name"] == "Appliance Name"
        assert appliances[1]["type"] == 0xAC
        assert appliances[1]["sn"] == "1234567890abcdef1234567890abcdef"
        assert appliances[1]["sn8"] == "0abcdef1"
        assert appliances[1]["model_number"] == 10
        assert appliances[1]["manufacturer_code"] == "1234"
        assert appliances[1]["model"] == "0abcdef1"
        assert appliances[1]["online"]

        assert appliances[2]["name"] == "Appliance Name 2"
        assert appliances[2]["type"] == 0xAC
        assert appliances[2]["sn"] == ""
        assert appliances[2]["sn8"] == ""
        assert appliances[2]["model_number"] == 0
        assert appliances[2]["manufacturer_code"] == "1234"
        assert appliances[2]["model"] == ""
        assert not appliances[2]["online"]

        appliances = await cloud.list_appliances(1)
        assert appliances is None

    async def test_msmartcloud_get_device_info(self) -> None:
        """Test MSmartCloud get_device_info"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["msmartcloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device["name"] == "Appliance Name"
        assert device["type"] == 0xAC
        assert device["sn"] == "1234567890abcdef1234567890abcdef"
        assert device["sn8"] == "0abcdef1"
        assert device["model_number"] == 10
        assert device["manufacturer_code"] == "1234"
        assert device["model"] == "0abcdef1"
        assert device["online"]

    async def test_msmartloud_download_lua(self) -> None:
        """Test MSmartCloud download_lua"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["msmartcloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ]
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="4ABE0FE395F3AD3B6BC4D223F1ADFA7C")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "MSmartHome", session=session, account="account", password="password"
        )
        assert cloud is not None
        assert await cloud.login()

        if not os.path.exists("/tmp/download"):
            os.mkdir("/tmp/download")
        file = await cloud.download_lua("/tmp/download", 10, "00000000", "0xAC", "0010")
        assert file is not None
        assert os.path.exists(file)
        os.remove(file)
        os.removedirs("/tmp/download")
