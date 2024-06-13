from enum import IntEnum
from importlib import import_module
from typing import Any


class DeviceType(IntEnum):
    """Device Type."""

    A0 = 0xA0
    A1 = 0xA1
    B0 = 0xB0
    B3 = 0xB3
    B6 = 0xB6
    C2 = 0xC2
    CA = 0xCA
    CD = 0xCD
    CF = 0xCF
    DB = 0xDB
    E1 = 0xE1
    E3 = 0xE3
    E8 = 0xE8
    EC = 0xEC
    FA = 0xFA
    FC = 0xFC
    X13 = 0x13
    X34 = 0x34
    AC = 0xAC
    B1 = 0xB1
    B4 = 0xB4
    BF = 0xBF
    C3 = 0xC3
    CC = 0xCC
    CE = 0xCE
    DA = 0xDA
    DC = 0xDC
    E2 = 0xE2
    E6 = 0xE6
    EA = 0xEA
    ED = 0xED
    FB = 0xFB
    FD = 0xFD
    X26 = 0x26
    X40 = 0x40


def device_selector(
    name: str,
    device_id: int,
    device_type: int,
    ip_address: str,
    port: int,
    token: str,
    key: str,
    protocol: int,
    model: str,
    subtype: int,
    customize: str,
) -> Any:
    try:
        if device_type < DeviceType.A0:
            device_path = f".{'x{:02x}'.format(device_type)}"
        else:
            device_path = f".{'{:02x}'.format(device_type)}"
        module = import_module(device_path, __package__)
        device = module.MideaAppliance(
            name=name,
            device_id=device_id,
            ip_address=ip_address,
            port=port,
            token=token,
            key=key,
            protocol=protocol,
            model=model,
            subtype=subtype,
            customize=customize,
        )
    except ModuleNotFoundError:
        device = None
    return device
