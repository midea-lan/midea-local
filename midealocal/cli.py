"""Midea local CLI."""

import asyncio
import contextlib
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

session = aiohttp.ClientSession()


async def _get_keys(args: Namespace, device_id: int) -> dict[int, dict[str, Any]]:
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
        logging.error("No devices found.")
        return

    # Dump only basic device info from the base class
    logging.info("Found %d devices.", len(devices))
    for device in devices.values():
        keys = (
            {0: {"token": "", "key": ""}}
            if device["protocol"] == ProtocolVersion.V3
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
            if dev.connect(False, False):
                logging.info("Found device:\n%s", dev)
                dev.close()
                break
            dev.close()


def _message(args: Namespace) -> None:
    """Load message into device."""
    device = device_selector(
        device_id=args.device,
        name=args.device,
        device_type=args.type,
        ip_address="192.168.192.168",
        port=6664,
        protocol=ProtocolVersion.V2,
        model="0000",
        token="",
        key="",
        subtype=0,
        customize="",
    )
    device.close()

    result = device.process_message(args.message)

    logging.info("Parsed message: %s", result)


def _download(args: Namespace) -> None:
    """Download a device's protocol implementation from the cloud."""
    # Use discovery to to find device information
    logging.info("Discovering %s on local network.", args.host)


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
        help="Set Cloud name, options are: " + ", ".join(clouds.keys()),
        action="store_true",
    )

    # Setup discover parser
    discover_parser = subparsers.add_parser(
        "discover",
        description="Discover device(s) on the local network.",
        parents=[common_parser],
    )
    discover_parser.add_argument(
        "host",
        help="Hostname or IP address of a single device to discover.",
        default=None,
    )
    discover_parser.set_defaults(func=_discover)

    # Setup query parser
    query_parser = subparsers.add_parser(
        "query",
        description="Query information from a device on the local network.",
        parents=[common_parser],
    )
    query_parser.add_argument("host", help="Hostname or IP address of device.")
    query_parser.add_argument(
        "--auto",
        help="Automatically authenticate V3 devices.",
        action="store_true",
    )
    query_parser.add_argument(
        "--id",
        help="Device ID for V3 devices.",
        dest="device_id",
        type=int,
        default=0,
    )
    query_parser.add_argument(
        "--token",
        help="Authentication token for V3 devices.",
        type=bytes.fromhex,
    )
    query_parser.add_argument(
        "--key",
        help="Authentication key for V3 devices.",
        type=bytes.fromhex,
    )
    query_parser.set_defaults(func=_discover)

    decode_msg_parser = subparsers.add_parser(
        "decode",
        description="Decode a message received to a device.",
    )
    query_parser.add_argument(
        "device",
        help="Device ID.",
        dest="device_id",
        type=int,
    )
    query_parser.add_argument(
        "type",
        help="Device type.",
        type=bytes.fromhex,
        required=True,
    )
    decode_msg_parser.add_argument(
        "message",
        help="Received message",
        type=bytes.fromhex,
        required=True,
    )
    decode_msg_parser.set_defaults(func=_message)

    # Setup download parser
    download = subparsers.add_parser(
        "download",
        description="Download a device's lua implementation from the cloud.",
        parents=[common_parser],
    )
    download.add_argument("host", help="Hostname or IP address of device.")
    download.set_defaults(func=_download)

    # Run with args
    _run(parser.parse_args())


def _run(args: Namespace) -> NoReturn:
    """Do setup logging, validate args and execute the desired function."""
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

    with contextlib.suppress(KeyboardInterrupt):
        asyncio.run(args.func(args))

    sys.exit(0)


if __name__ == "__main__":
    main()
