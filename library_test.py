"""Test script for midea-local library."""

import asyncio
import json
import logging
import sys
from argparse import ArgumentParser, Namespace
from pathlib import Path

import aiohttp

from midealocal.cloud import clouds, get_midea_cloud
from midealocal.devices import device_selector
from midealocal.discover import discover


def get_arguments() -> tuple[ArgumentParser, Namespace]:
    """Get parsed passed in arguments."""
    parser = ArgumentParser(description="midea-local library test")
    parser.add_argument(
        "--username",
        "-u",
        type=str,
        help="Set Cloud username",
    )
    parser.add_argument("--password", "-p", type=str, help="Set Cloud password")
    parser.add_argument(
        "--cloud_name",
        "-cn",
        type=str,
        help="Set Cloud name, options are: " + ", ".join(clouds.keys()),
    )
    parser.add_argument(
        "--configfile",
        "-cf",
        type=str,
        help="Load options from JSON config file. \
        Command line options override those in the file.",
    )
    parser.add_argument("--ip", "-i", type=str, help="Device or broadcast IP Address.")

    arguments = parser.parse_args()
    # Re-parse the command line
    # taking the options in the optional JSON file as a basis
    if arguments.configfile and Path(arguments.configfile).exists():
        with Path(arguments.configfile).open(encoding="utf-8") as f:
            arguments = parser.parse_args(namespace=Namespace(**json.load(f)))

    return parser, arguments


async def main() -> None:
    """Run main."""
    parser, args = get_arguments()

    if not args.password or not args.username or not args.cloud_name:
        print("You have to specify all parameters: username, password and Cloud name")
        parser.print_help()
        sys.exit(1)

    print("-" * 20)
    print("Starting network discovery...")
    devices = discover(ip_address=args.ip)
    print("-" * 20)
    print("Devices: ", devices)
    first_device = list(devices.values())[0]
    print("-" * 20)
    print("First device: ", first_device)
    # The device type is in hexadecimal as in midealocal/devices/TYPE
    type_code = hex(first_device["type"])[2:]
    print("-" * 20)
    print("First device type: ", type_code)

    session = aiohttp.ClientSession()
    cloud = get_midea_cloud(
        session=session,
        cloud_name=args.cloud_name,
        account=args.username,
        password=args.password,
    )
    cloud_keys = {}
    if cloud:
        cloud_keys = await cloud.get_keys(first_device["device_id"])
    print("-" * 20)
    print("Fist device Cloud info: ", cloud_keys)

    token = ""
    key = ""
    for v in cloud_keys.values():
        token = v["token"]
        key = v["key"]

    print("-" * 20)
    print("Fist device Cloud token: ", token)
    print("Fist device Cloud key:   ", key)

    # Select the device
    ac = device_selector(
        name=type_code,
        device_id=first_device["device_id"],
        device_type=first_device["type"],
        ip_address=first_device["ip_address"],
        port=first_device["port"],
        token=token,
        key=key,
        protocol=first_device["protocol"],
        model=first_device["model"],
        subtype=0,
        customize="",
    )

    # Connect and authenticate
    ac.connect()

    # Getting the attributes
    print("-" * 20)
    print("First device attributes: ", ac.attributes)

    # Close session
    await session.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("asyncio").setLevel(logging.INFO)
    logging.getLogger("charset_normalizer").setLevel(logging.INFO)
    asyncio.run(main())
