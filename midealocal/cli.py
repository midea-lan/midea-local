"""Midea local CLI."""

import asyncio
import contextlib
import inspect
import json
import logging
import sys
from argparse import ArgumentParser, BooleanOptionalAction, Namespace
from pathlib import Path
from typing import Any, NoReturn

import aiohttp
import platformdirs
from colorlog import ColoredFormatter

from midealocal.cloud import (
    SUPPORTED_CLOUDS,
    MideaCloud,
    get_default_cloud,
    get_midea_cloud,
    get_preset_account_cloud,
)
from midealocal.const import ProtocolVersion
from midealocal.device import (
    AuthException,
    MideaDevice,
    NoSupportedProtocol,
)
from midealocal.devices import device_selector
from midealocal.discover import SERIAL_TYPE1_LENGTH, discover
from midealocal.exceptions import (
    CloudLoginError,
    NoDeviceRegistered,
    SocketException,
)
from midealocal.version import __version__

_LOGGER = logging.getLogger("cli")

LOG_FORMAT = (
    "%(asctime)s.%(msecs)03d %(levelname)s (%(threadName)s) [%(name)s] %(message)s"
)


class MideaCLI:
    """Midea CLI."""

    session: aiohttp.ClientSession
    namespace: Namespace

    async def _get_cloud(self) -> MideaCloud:
        """Get cloud instance."""
        if not hasattr(self, "session"):
            self.session = aiohttp.ClientSession()

        if (
            not self.namespace.cloud_name
            or not self.namespace.username
            or not self.namespace.password
        ):
            default_cloud = get_preset_account_cloud()
            default_cloud_name = get_default_cloud()
            _LOGGER.info("Using preset account.")
            return get_midea_cloud(
                cloud_name=default_cloud_name,
                session=self.session,
                account=default_cloud["username"],
                password=default_cloud["password"],
            )

        return get_midea_cloud(
            cloud_name=self.namespace.cloud_name,
            session=self.session,
            account=self.namespace.username,
            password=self.namespace.password,
        )

    async def _get_keys(self, device_id: int) -> dict[int, dict[str, Any]]:
        cloud = await self._get_cloud()
        default_keys = await cloud.get_default_keys()
        try:
            logged_in = await cloud.login()
        except CloudLoginError as err:
            _LOGGER.warning(
                "Cloud login failed (%s). Using only default keys.",
                err,
            )
            return default_keys
        if not logged_in:
            _LOGGER.warning(
                "Failed to authenticate to the cloud. Using only default keys.",
            )
            return default_keys
        try:
            cloud_keys = await cloud.get_cloud_keys(device_id)
        except NoDeviceRegistered:
            _LOGGER.warning(
                "The cloud account has no paired device matching id %s. "
                "Sign in with the account that added the device in the Midea "
                "app. Using only default keys.",
                device_id,
            )
            return default_keys

        return {**cloud_keys, **default_keys}

    async def discover(self) -> list[MideaDevice]:
        """Discover device information."""
        device_list: list[MideaDevice] = []

        devices = discover(ip_address=self.namespace.host)

        if len(devices) == 0:
            _LOGGER.error("No devices found.")
            return device_list

        # Dump only basic device info from the base class
        _LOGGER.info("Found %d devices.", len(devices))
        # get sn
        if getattr(self.namespace, "get_sn", False):
            _LOGGER.info("Found devices: %s", devices)
            return device_list
        for device in devices.values():
            keys = (
                {0: {"token": "", "key": ""}}
                if device["protocol"] != ProtocolVersion.V3
                else await self._get_keys(device["device_id"])
            )

            for key in keys.values():
                dev = device_selector(
                    name=device["device_id"],
                    device_id=device["device_id"],
                    device_type=device["type"],
                    ip_address=device["ip_address"],
                    port=device["port"],
                    token=key["token"],
                    key=key["key"],
                    device_protocol=device["protocol"],
                    model=device["model"],
                    subtype=0,
                    customize="",
                    mac=device["mac"],
                    serial_number=device["sn"],
                )
                _LOGGER.debug("Opening socket for device.")
                if dev.connect():
                    success = False
                    try:
                        # connect() already authenticates V3 devices, so there
                        # is no need to call authenticate() again here.
                        _LOGGER.debug("Trying to retrieve device attributes.")
                        dev.refresh_status(True)
                        _LOGGER.info("Found device:\n%s", dev.attributes)
                        device_list.append(dev)
                        success = True
                    except AuthException:
                        _LOGGER.debug("Unable to connect with key: %s", key)
                    except SocketException:
                        _LOGGER.exception("Device socket closed.")
                    except NoSupportedProtocol:
                        _LOGGER.exception("Unable to retrieve device attributes.")
                    except OSError:
                        # OSError covers TimeoutError/ConnectionResetError raised
                        # by authenticate()/refresh_status(); catch it so one
                        # unreachable device doesn't abort the whole scan.
                        _LOGGER.exception("Connection error during device query.")
                    finally:
                        if not success:
                            dev.close_socket()
        return device_list

    def message(self) -> None:
        """Load message into device."""
        device_type = int(self.namespace.message[2])

        device = device_selector(
            device_id=0,
            name="",
            device_type=device_type,
            ip_address="192.168.192.168",
            port=6664,
            device_protocol=ProtocolVersion.V2,
            model="0000",
            token="",
            key="",
            subtype=0,
            customize="",
        )

        result = device.process_message(self.namespace.message)

        _LOGGER.info("Parsed message: %s", result)

    def save(self) -> None:
        """Save credentials to config file."""
        data = {
            "username": self.namespace.username,
            "password": self.namespace.password,
            "cloud_name": self.namespace.cloud_name,
        }
        json_data = json.dumps(data)
        file = get_config_file_path(not self.namespace.user)
        with file.open(mode="w+", encoding="utf-8") as f:
            f.write(json_data)

    async def _download_device(
        self,
        cloud: MideaCloud,
        device_type: int,
        device_sn: str,
        model: str | None,
        manufacturer_code: str = "0000",
    ) -> None:
        """Download the lua and plugin files for a single device.

        Any failure is confined to this device: bulk :meth:`download` iterates
        over every appliance in the account, so a network, decryption, or
        file-write error for one device must not abort the rest.
        """
        _LOGGER.debug(
            "Download lua file for %s [%s] %s",
            device_sn,
            hex(device_type),
            model,
        )
        # A plain error (no traceback) is the right output for the expected
        # NotImplementedError limitations below, so TRY400 (use
        # logging.exception) does not apply to those handlers.
        try:
            lua = await cloud.download_lua(
                str(Path()),
                device_type,
                device_sn,
                model,
                manufacturer_code,
            )
        except NotImplementedError:
            # Defensive: every supported cloud now implements lua download
            # (美的美居, SmartHome, and the MideaAirCloud variants), so only the
            # abstract base class reaches here. Without lua there is no point
            # attempting the plugin, so report and stop.
            _LOGGER.error(  # noqa: TRY400
                "The '%s' cloud does not support downloading lua files.",
                self.namespace.cloud_name,
            )
            return
        except Exception:
            # Without lua there is no point attempting the plugin.
            _LOGGER.exception("Failed to download lua file for %s", device_sn)
            return

        # A cloud can also signal failure by returning None without raising.
        if lua is None:
            _LOGGER.error("Failed to download lua file for %s", device_sn)
            return
        _LOGGER.info("Downloaded lua file: %s", lua)

        _LOGGER.debug(
            "Download plugin file for %s [%s]",
            device_sn,
            hex(device_type),
        )
        try:
            plugin = await cloud.download_plugin(str(Path()), device_type, device_sn)
            _LOGGER.info("Downloaded plugin file: %s", plugin)
        except NotImplementedError:
            # The legacy MideaAirCloud backend serves lua files but not plugins,
            # so the lua download above still succeeds; report the plugin gap
            # without discarding the lua result.
            _LOGGER.warning(
                "The '%s' cloud does not support downloading plugin files; "
                "lua file downloaded only.",
                self.namespace.cloud_name,
            )
        except Exception:
            _LOGGER.exception("Failed to download plugin file for %s", device_sn)

    async def _download_by_sn(self, cloud: MideaCloud, device_sn: str) -> None:
        """Download for a single serial number.

        Device type is resolved with the following precedence, chosen to keep
        the legacy behavior intact while fixing device types the serial number
        cannot express:

        1. an explicit ``--device-type`` argument;
        2. the device's entry in the cloud account -- authoritative, and needed
           because some serials (e.g. air conditioners) carry ``00`` where the
           type byte would be;
        3. parsing the serial number itself -- the legacy fallback, which keeps
           download-by-SN working for devices absent from the account.
        """
        # 1. explicit device type: legacy path, no cloud account lookup needed
        if self.namespace.device_type:
            device_type = int.from_bytes(self.namespace.device_type)
            await self._download_device(
                cloud,
                device_type,
                device_sn,
                str(device_sn[9:17]),
            )
            return

        # 2. resolve type/model from the cloud account (fixes AC-style serials)
        appliances = await cloud.list_appliances(home_id=None) or {}
        appliance = next(
            (a for a in appliances.values() if a["sn"] == device_sn),
            None,
        )
        if appliance is not None:
            await self._download_device(
                cloud,
                appliance["type"],
                device_sn,
                appliance["model"],
                appliance["manufacturer_code"],
            )
            return

        # 3. legacy fallback: derive the type from the serial number
        device_type = 0
        if len(device_sn) == SERIAL_TYPE1_LENGTH:
            # --device-sn is an unvalidated string; a non-hex type byte would
            # otherwise raise here.
            with contextlib.suppress(ValueError):
                device_type = int.from_bytes(bytes.fromhex(device_sn[4:6]))
        await self._download_device(
            cloud,
            device_type,
            device_sn,
            str(device_sn[9:17]),
        )

    async def download(self) -> None:
        """Download lua and plugin files from the cloud.

        The target device(s) are resolved in one of three ways:

        * ``--host``: discover the device on the LAN; its type and model come
          from the discovery reply.
        * ``--device-sn``: download a single device by serial number (see
          :meth:`_download_by_sn` for how the device type is resolved).
        * neither: download for every device in the cloud account.
        """
        cloud = await self._get_cloud()
        _LOGGER.debug("Try to authenticate to the cloud.")
        try:
            logged_in = await cloud.login()
        except CloudLoginError as err:
            # A specific, expected login failure -- the code/message is the
            # useful output, not a traceback.
            _LOGGER.error("Cloud login failed: %s", err)  # noqa: TRY400
            return
        if not logged_in:
            _LOGGER.error("Failed to authenticate to the cloud.")
            return

        # download with host ip: LAN discovery provides the device type
        if self.namespace.host:
            devices = discover(ip_address=self.namespace.host)
            if len(devices) == 0:
                _LOGGER.error("No devices found.")
                return
            _, device = devices.popitem()
            await self._download_device(
                cloud,
                device["type"],
                device["sn"],
                device["model"],
            )
            return

        # download with SN
        if self.namespace.device_sn:
            await self._download_by_sn(cloud, str(self.namespace.device_sn))
            return

        # no host and no SN: download every device in the cloud account
        appliances = await cloud.list_appliances(home_id=None) or {}
        if not appliances:
            _LOGGER.error("No devices found in the cloud account.")
            return
        _LOGGER.info("Found %d device(s) in the cloud account.", len(appliances))
        for appliance in appliances.values():
            await self._download_device(
                cloud,
                appliance["type"],
                appliance["sn"],
                appliance["model"],
                appliance["manufacturer_code"],
            )

    async def set_attribute(self) -> None:
        """Set attribute for device."""
        device_list = await self.discover()
        try:
            if len(device_list) != 1:
                return

            _LOGGER.info(
                "Setting attribute %s for %s [%s]",
                self.namespace.attribute,
                device_list[0].device_id,
                device_list[0].device_type,
            )
            device_list[0].set_attribute(
                self.namespace.attribute,
                self._cast_attr_value(),
            )
            await asyncio.sleep(2)
            device_list[0].refresh_status(True)
            _LOGGER.info("New device status:\n%s", device_list[0].attributes)
        finally:
            for dev in device_list:
                dev.close_socket()

    def _cast_attr_value(self) -> int | bool | str:
        if self.namespace.attr_type == "bool":
            return self.namespace.value not in ["false", "False", "0", ""]
        if self.namespace.attr_type == "int":
            return int(self.namespace.value)
        return str(self.namespace.value)

    def run(self, namespace: Namespace) -> None:
        """Do setup logging, validate args and execute the desired function."""
        self.namespace = namespace
        # Configure logging
        if self.namespace.debug:
            logging.basicConfig(level=logging.DEBUG)
            # Keep httpx as info level
            logging.getLogger("asyncio").setLevel(logging.INFO)
            logging.getLogger("charset_normalizer").setLevel(logging.INFO)
        else:
            logging.basicConfig(level=logging.INFO)
            # Set httpx to warning level
            logging.getLogger("asyncio").setLevel(logging.WARNING)
            logging.getLogger("charset_normalizer").setLevel(logging.WARNING)

        fmt = LOG_FORMAT
        colorfmt = f"%(log_color)s{fmt}%(reset)s"
        logging.getLogger().handlers[0].setFormatter(
            ColoredFormatter(
                colorfmt,
                datefmt="%Y-%m-%d %H:%M:%S",
                reset=True,
                log_colors={
                    "DEBUG": "cyan",
                    "INFO": "green",
                    "WARNING": "yellow",
                    "ERROR": "red",
                    "CRITICAL": "red",
                },
            ),
        )

        with contextlib.suppress(KeyboardInterrupt):
            if inspect.iscoroutinefunction(self.namespace.func):
                asyncio.run(self.namespace.func())
            else:
                self.namespace.func()

        if hasattr(self, "session") and self.session:
            asyncio.run(self.session.close())


def get_config_file_path(relative: bool = False) -> Path:
    """Get the config file path."""
    local_path = Path("midea-local.json")
    if relative or local_path.exists():
        return local_path
    return platformdirs.user_config_path(appname="midea-local").joinpath(
        "midea-local.json",
    )


def main() -> NoReturn:
    """Launch main entry."""
    cli = MideaCLI()
    # Define the main parser to select subcommands
    parser = ArgumentParser(description="Command line utility for midea-local.")
    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"midea-local version: {__version__}",
    )
    subparsers = parser.add_subparsers(title="Command", dest="command", required=True)

    # Define some common arguments
    common_parser = ArgumentParser(add_help=False)
    common_parser.add_argument(
        "-d",
        "--debug",
        help="Enable debug logging.",
        action="store_true",
    )
    common_parser.add_argument(
        "--username",
        "-u",
        type=str,
        help="Set cloud username",
    )
    common_parser.add_argument(
        "--password",
        "-p",
        type=str,
        help="Set cloud password",
    )
    common_parser.add_argument(
        "--cloud-name",
        "-cn",
        type=str,
        help="Set Cloud name",
        choices=SUPPORTED_CLOUDS.keys(),
    )

    # Setup discover parser
    discover_parser = subparsers.add_parser(
        "discover",
        description="Discover device(s) on the local network.",
        parents=[common_parser],
    )
    discover_parser.add_argument(
        "--host",
        help="Hostname or IP address of a single device to discover.",
        default=None,
    )
    discover_parser.add_argument(
        "--get_sn",
        help="Get device SN with host ip.",
        default=False,
        action=BooleanOptionalAction,
    )
    discover_parser.set_defaults(func=cli.discover)

    decode_msg_parser = subparsers.add_parser(
        "decode",
        description="Decode a message received to a device.",
        parents=[common_parser],
    )
    decode_msg_parser.add_argument(
        "message",
        help="Received message",
        type=bytes.fromhex,
    )
    decode_msg_parser.set_defaults(func=cli.message)

    save_parser = subparsers.add_parser(
        "save",
        description="Save config file with cloud parameters.",
        parents=[common_parser],
    )
    save_parser.add_argument(
        "--user",
        help="Save config file in your user config folder.",
        action="store_true",
    )
    save_parser.set_defaults(func=cli.save)

    download_parser = subparsers.add_parser(
        "download",
        description="Download lua scripts from cloud.",
        parents=[common_parser],
    )
    download_parser.add_argument(
        "--device-type",
        help="Device Type",
        type=bytes.fromhex,
    )
    download_parser.add_argument("--device-sn", help="Device SN")
    download_parser.add_argument(
        "--host",
        help="IP Address of the device.",
    )
    download_parser.set_defaults(func=cli.download)

    attribute_parser = subparsers.add_parser(
        "setattr",
        description="Set device attribute after discover.",
        parents=[common_parser],
    )
    attribute_parser.add_argument(
        "host",
        help="Hostname or IP address of a single device.",
        default=None,
    )
    attribute_parser.add_argument(
        "attribute",
        help="Attribute name.",
        default=None,
    )
    attribute_parser.add_argument(
        "value",
        help="Attribute value.",
        default=None,
    )
    attribute_parser.add_argument(
        "--attr-type",
        help="Attribute type.",
        type=str,
        default="int",
        choices=["bool", "int", "str"],
    )
    attribute_parser.set_defaults(func=cli.set_attribute)

    config = get_config_file_path()
    namespace = parser.parse_args()
    if config.exists():
        with config.open(encoding="utf-8") as f:
            config_data = json.load(f)
            for key, value in config_data.items():
                if not getattr(namespace, key):
                    setattr(namespace, key, value)

    # Run with args
    cli.run(namespace)
    sys.exit(0)


if __name__ == "__main__":
    main()
