"""Midea local devices."""

from importlib import import_module
from typing import cast

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice
from midealocal.device_info import DeviceCredentials, DeviceDescriptor, DiscoveryProfile


def create_device(
    descriptor: DeviceDescriptor,
    credentials: DeviceCredentials,
    profile: DiscoveryProfile | None = None,
    *,
    customize: str = "",
) -> MideaDevice:
    """Build a device from known inputs without discovery or network access.

    A valid profile restores discovery hints only. A fresh status read remains
    necessary before using cached appliance settings to build control messages.
    """
    device = cast(
        "MideaDevice | None",
        device_selector(
            **descriptor.to_dict(),
            token=credentials.token,
            key=credentials.key,
            customize=customize,
        ),
    )
    if device is None:
        msg = f"Unsupported device type: {descriptor.device_type:#04x}"
        raise ValueError(msg)
    if profile is not None and profile.is_valid_for(descriptor):
        device.restore_discovery_profile(profile)
    return device


def device_selector(
    name: str,
    device_id: int,
    device_type: int,
    ip_address: str,
    port: int,
    token: str,
    key: str,
    device_protocol: ProtocolVersion,
    model: str,
    subtype: int,
    customize: str,
    mac: str | None = None,
    serial_number: str | None = None,
) -> MideaDevice:
    """Select and load device."""
    try:
        if device_type < DeviceType.A0:
            device_path = f".{f'x{device_type:02x}'}"
        else:
            device_path = f".{f'{device_type:02x}'}"
        module = import_module(device_path, __package__)
        device = module.MideaAppliance(
            name=name,
            device_id=device_id,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            device_protocol=device_protocol,
            model=model,
            subtype=subtype,
            customize=customize,
            mac=mac,
            serial_number=serial_number,
        )
    except ModuleNotFoundError:
        device = None
    return cast("MideaDevice", device)
