"""Test cloud"""

from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import IsolatedAsyncioTestCase
from unittest.mock import AsyncMock, Mock

import pytest
from aiohttp import ClientResponseError

from midealocal.cloud import (
    MeijuCloud,
    MideaAirCloud,
    MideaCloud,
    MSmartHomeCloud,
    get_midea_cloud,
)


class CloudTest(IsolatedAsyncioTestCase):
    """Cloud test case."""

    responses: dict[str, bytes] = {}

    def setUp(self) -> None:
        """Set tests up."""
        file_path = Path(__file__)
        for file in Path.iterdir(Path(file_path.parent, "responses")):
            file_path = Path(file)
            with file_path.open(
                encoding="utf-8",
            ) as f:
                self.responses[file_path.name] = bytes(f.read(), encoding="utf-8")

    def test_get_midea_cloud(self) -> None:
        """Test get midea cloud"""
        assert isinstance(get_midea_cloud("美的美居", None, "", ""), MeijuCloud)
        assert isinstance(get_midea_cloud("MSmartHome", None, "", ""), MSmartHomeCloud)
        assert isinstance(get_midea_cloud("Midea Air", None, "", ""), MideaAirCloud)
        assert isinstance(get_midea_cloud("NetHome Plus", None, "", ""), MideaAirCloud)
        assert isinstance(get_midea_cloud("Ariston Clima", None, "", ""), MideaAirCloud)

    async def test_midea_cloud_unimplemented(self) -> None:
        """Test unimplemented MideaCloud methods"""
        session = Mock()
        security = Mock()
        cloud = MideaCloud(
            session=session,
            security=security,
            app_id="appid",
            app_key="appkey",
            account="account",
            password="password",
            api_url="http://api.url/",
        )
        with pytest.raises(NotImplementedError):
            await cloud.login()
        with pytest.raises(NotImplementedError):
            await cloud.list_appliances(None)

    async def test_meijucloud_login_success(self) -> None:
        """Test MeijuCloud login"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_meijucloud_login_invalid_user(self) -> None:
        """Test MeijuCloud login invalid user"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_meijucloud_get_keys(self) -> None:
        """Test MeijuCloud get_keys"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["meijucloud_get_keys.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
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
            return_value=self.responses["meijucloud_list_home.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 2
        assert homes[1] == "Home 1"
        assert homes[2] == "Home 2"

        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        assert await cloud.list_home() is None

    async def test_meijucloud_list_appliances(self) -> None:
        """Test MeijuCloud list_appliances"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_list_appliances.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances("1")
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "mySecretKey"
        assert appliance.get("sn8") == "9d52c159"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "Product Model"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == "00000000"
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "00000000"
        assert not appliance.get("online")

        appliances = await cloud.list_appliances("1")
        assert appliances is None

    async def test_meijucloud_get_device_info(self) -> None:
        """Test MeijuCloud get_device_info"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_get_device_info.json"],
                self.responses["meijucloud_get_device_info_alt.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "mySecretKey"
        assert device.get("sn8") == "9d52c159"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "Product Model"
        assert device.get("online")

        device = await cloud.get_device_info(2)
        assert device is not None
        assert device.get("name") == "Appliance Name 2"
        assert device.get("type") == 0xAC
        assert device.get("sn") == ""
        assert device.get("sn8") == "00000000"
        assert device.get("model_number") == 0
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "00000000"
        assert not device.get("online")

        device = await cloud.get_device_info(99)
        assert device is None

    async def test_meijucloud_download_lua(self) -> None:
        """Test MeijuCloud download_lua"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["cloud_login_id.json"],
                self.responses["meijucloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="9d52c159dcdd32bac5109cf54080fca7")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "美的美居",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert file is not None
            file_path = Path(file)
            assert Path.exists(file_path)
            Path.unlink(file_path)

            res.status = 404
            assert (
                await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010") is None
            )

    async def test_msmartcloud_login_success(self) -> None:
        """Test MSmartCloud login"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_msmartcloud_login_invalid_user(self) -> None:
        """Test MSmartCloud login invalid user"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["cloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_msmartcloud_list_home(self) -> None:
        """Test MSmartCloud list_home"""
        session = Mock()
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
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
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
                self.responses["cloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(None)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "1234567890abcdef1234567890abcdef"
        assert appliance.get("sn8") == "0abcdef1"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "0abcdef1"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == ""
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == ""
        assert not appliance.get("online")

        appliances = await cloud.list_appliances(None)
        assert appliances is None

    async def test_msmartcloud_get_device_info(self) -> None:
        """Test MSmartCloud get_device_info"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["msmartcloud_list_appliances.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "1234567890abcdef1234567890abcdef"
        assert device.get("sn8") == "0abcdef1"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "0abcdef1"
        assert device.get("online")

        device = await cloud.get_device_info(99)
        assert device is None

    async def test_msmartcloud_download_lua(self) -> None:
        """Test MSmartCloud download_lua"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["msmartcloud_reroute.json"],
                self.responses["cloud_login_id.json"],
                self.responses["msmartcloud_login.json"],
                self.responses["meijucloud_download_lua.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        res = Mock()
        res.status = 200
        res.text = AsyncMock(return_value="4ABE0FE395F3AD3B6BC4D223F1ADFA7C")
        session.get = AsyncMock(return_value=res)
        cloud = get_midea_cloud(
            "MSmartHome",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        with TemporaryDirectory() as tmpdir:
            file = await cloud.download_lua(tmpdir, 10, "00000000", "0xAC", "0010")
            assert file is not None
            file_path = Path(file)
            assert Path.exists(file_path)
            Path.unlink(file_path)

    async def test_mideaaircloud_login_success(self) -> None:
        """Test MideaAirCloud login"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

    async def test_mideaaircloud_login_invalid_user(self) -> None:
        """Test MideaAirCloud login invalid user"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            return_value=self.responses["mideaaircloud_invalid_response.json"],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert not await cloud.login()

    async def test_mideaaircloud_list_home(self) -> None:
        """Test MideaAirCloud list_home"""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        homes = await cloud.list_home()
        assert homes is not None
        assert len(homes.keys()) == 1

    async def test_mideaaircloud_list_appliances(self) -> None:
        """Test MideaAirCloud list_appliances"""
        session = Mock()
        response = Mock()
        response.read = AsyncMock(
            side_effect=[
                self.responses["mideaaircloud_login_id.json"],
                self.responses["mideaaircloud_login.json"],
                self.responses["mideaaircloud_list_appliances.json"],
                self.responses["mideaaircloud_invalid_response.json"],
            ],
        )
        session.request = AsyncMock(return_value=response)
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()
        appliances = await cloud.list_appliances(None)
        assert appliances is not None
        assert len(appliances.keys()) == 2
        appliance = appliances.get(1)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == "1234567890abcdef1234567890abcdef"
        assert appliance.get("sn8") == "0abcdef1"
        assert appliance.get("model_number") == 10
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == "0abcdef1"
        assert appliance.get("online")

        appliance = appliances.get(2)
        assert appliance is not None
        assert appliance.get("name") == "Appliance Name 2"
        assert appliance.get("type") == 0xAC
        assert appliance.get("sn") == ""
        assert appliance.get("sn8") == ""
        assert appliance.get("model_number") == 0
        assert appliance.get("manufacturer_code") == "1234"
        assert appliance.get("model") == ""
        assert not appliance.get("online")

        appliances = await cloud.list_appliances(None)
        assert appliances is None

    async def test_mideaaircloud_get_device_info(self) -> None:
        """Test MideaAirCloud get_device_info"""
        session = Mock()
        response1 = Mock()
        response1.read = AsyncMock(
            return_value=self.responses["mideaaircloud_login_id.json"],
        )
        response2 = Mock()
        response2.read = AsyncMock(
            return_value=self.responses["mideaaircloud_login.json"],
        )
        response3 = Mock()
        response3.read = AsyncMock(
            return_value=self.responses["mideaaircloud_list_appliances.json"],
        )

        session.request = AsyncMock(
            side_effect=[
                response1,
                response2,
                response3,
                ClientResponseError(Mock(), Mock()),
                ClientResponseError(Mock(), Mock()),
                ClientResponseError(Mock(), Mock()),
                ClientResponseError(Mock(), Mock()),
            ],
        )
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        assert await cloud.login()

        device = await cloud.get_device_info(1)
        assert device is not None
        assert device.get("name") == "Appliance Name"
        assert device.get("type") == 0xAC
        assert device.get("sn") == "1234567890abcdef1234567890abcdef"
        assert device.get("sn8") == "0abcdef1"
        assert device.get("model_number") == 10
        assert device.get("manufacturer_code") == "1234"
        assert device.get("model") == "0abcdef1"
        assert device.get("online")

        device = await cloud.get_device_info(99)
        assert device is None

    async def test_mideaaircloud_download_lua(self) -> None:
        """Test MideaAirCloud download_lua"""
        session = Mock()
        cloud = get_midea_cloud(
            "Midea Air",
            session=session,
            account="account",
            password="password",
        )
        assert cloud is not None
        with pytest.raises(NotImplementedError):
            await cloud.download_lua("/tmp/download", 10, "00000000", "0xAC", "0010")
