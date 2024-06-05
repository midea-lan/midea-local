from importlib import import_module
from typing import Any


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
        if device_type < 0xA0:
            device_path = f".{'x%02x' % device_type}"
        else:
            device_path = f".{'%02x' % device_type}"
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
