"""Midea local CLI."""

import asyncio
import contextlib
import inspect
import logging
import sys
from argparse import ArgumentParser, Namespace
from typing import Any, NoReturn

import aiohttp
from colorlog import ColoredFormatter

from midealocal.cloud import clouds, get_midea_cloud
from midealocal.const import OPEN_MIDEA_APP_ACCOUNT, OPEN_MIDEA_APP_PASSWORD
from midealocal.device import ProtocolVersion
from midealocal.devices import device_selector
from midealocal.discover import discover
from midealocal.version import __version__

_LOGGER = logging.getLogger("cli")


async def _get_keys(args: Namespace, device_id: int) -> dict[int, dict[str, Any]]:
    session = aiohttp.ClientSession()
    with session:
        cloud = get_midea_cloud(
            cloud_name=args.cloud_name,
            session=session,
            account=args.username,
            password=args.password,
        )

        return await cloud.get_keys(device_id)


async def _discover(args: Namespace) -> None:
    """Discover device information."""
    devices = discover(ip_address=args.host)

    if len(devices) == 0:
        _LOGGER.error("No devices found.")
        return

    # Dump only basic device info from the base class
    _LOGGER.info("Found %d devices.", len(devices))
    for device in devices.values():
        keys = (
            {0: {"token": "", "key": ""}}
            if device["protocol"] != ProtocolVersion.V3
            else await _get_keys(args, device["device_id"])
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
                protocol=device["protocol"],
                model=device["model"],
                subtype=0,
                customize="",
            )

            if dev.connect():
                _LOGGER.info("Found device:\n%s", dev.attributes)
                break


def _message(args: Namespace) -> None:
    """Load message into device."""
    device_type = int(args.message[2])

    device = device_selector(
        device_id=0,
        name="",
        device_type=device_type,
        ip_address="192.168.192.168",
        port=6664,
        protocol=ProtocolVersion.V2,
        model="0000",
        token="",
        key="",
        subtype=0,
        customize="",
    )

    result = device.process_message(args.message)

    _LOGGER.info("Parsed message: %s", result)


def main() -> NoReturn:
    """Launch main entry."""
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
        default=OPEN_MIDEA_APP_ACCOUNT,
    )
    common_parser.add_argument(
        "--password",
        "-p",
        type=str,
        help="Set cloud password",
        default=OPEN_MIDEA_APP_PASSWORD,
    )
    common_parser.add_argument(
        "--cloud-name",
        "-cn",
        type=str,
        help="Set Cloud name",
        choices=clouds.keys(),
        default="MSmartHome",
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
        required=False,
        default=None,
    )
    discover_parser.set_defaults(func=_discover)

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
    decode_msg_parser.set_defaults(func=_message)

    # Run with args
    _run(parser.parse_args())


def _run(args: Namespace) -> NoReturn:
    """Do setup logging, validate args and execute the desired function."""
    # Configure logging
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
        # Keep httpx as info level
        logging.getLogger("asyncio").setLevel(logging.INFO)
        logging.getLogger("charset_normalizer").setLevel(logging.INFO)
    else:
        logging.basicConfig(level=logging.INFO)
        # Set httpx to warning level
        logging.getLogger("asyncio").setLevel(logging.WARNING)
        logging.getLogger("charset_normalizer").setLevel(logging.WARNING)

    fmt = (
        "%(asctime)s.%(msecs)03d %(levelname)s (%(threadName)s) [%(name)s] %(message)s"
    )
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
        if inspect.iscoroutinefunction(args.func):
            asyncio.run(args.func(args))
        else:
            args.func(args)

    sys.exit(0)


if __name__ == "__main__":
    main()
