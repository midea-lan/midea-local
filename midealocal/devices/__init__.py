"""Midea local devices."""

from collections.abc import Callable
from typing import cast

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice

from . import (
    a1,
    ac,
    ad,
    b0,
    b1,
    b3,
    b4,
    b6,
    b8,
    bf,
    c2,
    c3,
    ca,
    cc,
    cd,
    ce,
    cf,
    da,
    db,
    dc,
    e1,
    e2,
    e3,
    e6,
    e8,
    ea,
    ec,
    ed,
    fa,
    fb,
    fc,
    fd,
    x13,
    x26,
    x34,
    x40,
)

# Imported eagerly so device_selector() never imports at call time, which would
# be blocking I/O when called from an asyncio event loop.
_DEVICE_CLASSES: dict[int, Callable[..., MideaDevice]] = {
    DeviceType.A1: a1.MideaAppliance,
    DeviceType.AC: ac.MideaAppliance,
    DeviceType.AD: ad.MideaAppliance,
    DeviceType.B0: b0.MideaAppliance,
    DeviceType.B1: b1.MideaAppliance,
    DeviceType.B3: b3.MideaAppliance,
    DeviceType.B4: b4.MideaAppliance,
    DeviceType.B6: b6.MideaAppliance,
    DeviceType.B8: b8.MideaAppliance,
    DeviceType.BF: bf.MideaAppliance,
    DeviceType.C2: c2.MideaAppliance,
    DeviceType.C3: c3.MideaAppliance,
    DeviceType.CA: ca.MideaAppliance,
    DeviceType.CC: cc.MideaAppliance,
    DeviceType.CD: cd.MideaAppliance,
    DeviceType.CE: ce.MideaAppliance,
    DeviceType.CF: cf.MideaAppliance,
    DeviceType.DA: da.MideaAppliance,
    DeviceType.DB: db.MideaAppliance,
    DeviceType.DC: dc.MideaAppliance,
    DeviceType.E1: e1.MideaAppliance,
    DeviceType.E2: e2.MideaAppliance,
    DeviceType.E3: e3.MideaAppliance,
    DeviceType.E6: e6.MideaAppliance,
    DeviceType.E8: e8.MideaAppliance,
    DeviceType.EA: ea.MideaAppliance,
    DeviceType.EC: ec.MideaAppliance,
    DeviceType.ED: ed.MideaAppliance,
    DeviceType.FA: fa.MideaAppliance,
    DeviceType.FB: fb.MideaAppliance,
    DeviceType.FC: fc.MideaAppliance,
    DeviceType.FD: fd.MideaAppliance,
    DeviceType.X13: x13.MideaAppliance,
    DeviceType.X26: x26.MideaAppliance,
    DeviceType.X34: x34.MideaAppliance,
    DeviceType.X40: x40.MideaAppliance,
}


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
    if (device_class := _DEVICE_CLASSES.get(device_type)) is None:
        return cast("MideaDevice", None)
    return device_class(
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
