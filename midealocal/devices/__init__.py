from enum import IntEnum
from importlib import import_module
from typing import Any


class BodyType(IntEnum):
    """Body Type."""

    A0 = 0xA0
    A1 = 0xA1
    A4 = 0xA4
    B0 = 0xB0
    B1 = 0xB1
    B5 = 0xB5
    BB = 0xBB
    C0 = 0xC0
    C1 = 0xC1
    C3 = 0xC3
    C8 = 0xC8
    FF = 0xFF
    X00 = 0x00
    X01 = 0x01
    X02 = 0x02
    X03 = 0x03
    X04 = 0x04
    X05 = 0x05
    X06 = 0x06
    X07 = 0x07
    X0A = 0x0A
    X11 = 0x11
    X21 = 0x21
    X22 = 0x22
    X24 = 0x24
    X31 = 0x31
    X32 = 0x32
    X41 = 0x41
    X80 = 0x80


class DeviceType(IntEnum):
    """Device Type."""

    A0 = 0xA0
    A1 = 0xA1
    AC = 0xAC
    B0 = 0xB0
    B1 = 0xB1
    B3 = 0xB3
    B4 = 0xB4
    B6 = 0xB6
    BF = 0xBF
    C2 = 0xC2
    C3 = 0xC3
    CA = 0xCA
    CC = 0xCC
    CD = 0xCD
    CE = 0xCE
    CF = 0xCF
    DA = 0xDA
    DB = 0xDB
    DC = 0xDC
    E1 = 0xE1
    E2 = 0xE2
    E3 = 0xE3
    E6 = 0xE6
    E8 = 0xE8
    EA = 0xEA
    EC = 0xEC
    ED = 0xED
    FA = 0xFA
    FB = 0xFB
    FC = 0xFC
    FD = 0xFD
    X13 = 0x13
    X26 = 0x26
    X34 = 0x34
    X40 = 0x40


class SubBodyType(IntEnum):
    """Sub Body Type."""

    A0 = 0xA0
    A1 = 0xA1
    A2 = 0xA2
    B0 = 0xB0
    B1 = 0xB1
    B5 = 0xB5
    BB = 0xBB
    C0 = 0xC0
    C1 = 0xC1
    C3 = 0xC3
    X01 = 0x01
    X02 = 0x02
    X03 = 0x03
    X04 = 0x04
    X05 = 0x05
    X06 = 0x06
    X0A = 0x0A
    X10 = 0x10
    X11 = 0x11
    X12 = 0x12
    X13 = 0x13
    X16 = 0x16
    X20 = 0x20
    X21 = 0x21
    X22 = 0x22
    X24 = 0x24
    X30 = 0x30
    X31 = 0x31
    X32 = 0x32
    X3D = 0x3D
    X41 = 0x41
    X52 = 0x52


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
            protocol=protocol,
            model=model,
            subtype=subtype,
            customize=customize,
        )
    except ModuleNotFoundError:
        device = None
    return device
