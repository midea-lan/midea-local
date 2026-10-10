"""Device construction data and persistent discovery profile tests."""

import json
from dataclasses import replace
from unittest.mock import patch

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import MideaDevice
from midealocal.device_info import (
    DeviceCredentials,
    DeviceDescriptor,
    DiscoveryProfile,
)
from midealocal.devices import create_device
from midealocal.devices.ac import MideaACDevice
from midealocal.message import MessageType


@pytest.fixture
def descriptor() -> DeviceDescriptor:
    """Describe a device without performing network discovery."""
    return DeviceDescriptor(
        name="Office",
        device_id=123,
        device_type=DeviceType.AC,
        ip_address="192.0.2.10",
        port=6444,
        device_protocol=ProtocolVersion.V3,
        model="22012297",
        subtype=1,
        mac="00:11:22:33:44:55",
        serial_number="serial",
    )


def test_profile_json_roundtrip_contains_only_discovery_metadata(
    descriptor: DeviceDescriptor,
) -> None:
    """JSON persists protocol metadata but carries no state or credentials."""
    profile = DiscoveryProfile(
        descriptor=descriptor,
        message_protocol_version=2,
        capability_pages=(0, 1),
        capabilities={"cool_mode": True},
        temperature_limits={2: (16.0, 30.0)},
        created_at=1000,
    )
    document = json.loads(json.dumps(profile.to_dict()))
    assert DiscoveryProfile.from_dict(document) == profile
    assert set(document) == {
        "descriptor",
        "message_protocol_version",
        "capability_pages",
        "capabilities",
        "uses_subprotocol",
        "temperature_limits",
        "created_at",
        "schema_version",
    }


@pytest.mark.parametrize(
    "changes",
    [
        {"device_id": 456},
        {"device_type": DeviceType.A1},
        {"model": "other"},
        {"subtype": 2},
        {"device_protocol": ProtocolVersion.V2},
        {"mac": "00:11:22:33:44:66"},
        {"serial_number": "other"},
    ],
)
def test_profile_rejects_other_identity(
    descriptor: DeviceDescriptor,
    changes: dict,
) -> None:
    """Cached metadata cannot cross device, firmware model, or transport identity."""
    profile = DiscoveryProfile(
        descriptor=descriptor,
        message_protocol_version=2,
        created_at=1000,
    )
    assert not profile.is_valid_for(replace(descriptor, **changes), now=1001)
    assert profile.is_valid_for(
        replace(descriptor, ip_address="192.0.2.11", name="New name"),
        now=1001,
    )


@pytest.mark.parametrize("now", [999, 1000 + 7 * 86400])
def test_profile_rejects_expired_or_future_snapshot(
    descriptor: DeviceDescriptor,
    now: float,
) -> None:
    """Future timestamps and elapsed cache lifetimes require fresh discovery."""
    profile = DiscoveryProfile(
        descriptor=descriptor,
        message_protocol_version=2,
        created_at=1000,
    )
    assert not profile.is_valid_for(descriptor, now=now)


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("schema_version", 99),
        ("message_protocol_version", True),
        ("created_at", float("nan")),
        ("capabilities", {"power": 1}),
        ("capability_pages", [2]),
        ("capability_pages", [True]),
        ("supported_queries", ["MessageQuery"]),
        ("temperature_limits", {"2": [30, 16]}),
        ("temperature_limits", {"1": [16, 30]}),
        ("attributes", {"power": True}),
        ("unsupported_queries", ["MessageQuery"]),
    ],
)
def test_profile_rejects_invalid_cache_data(
    descriptor: DeviceDescriptor,
    field: str,
    value: object,
) -> None:
    """Invalid schema and transient state cannot enter a loaded profile."""
    data = DiscoveryProfile(descriptor=descriptor, message_protocol_version=2).to_dict()
    data[field] = value
    with pytest.raises(ValueError, match="Invalid"):
        DiscoveryProfile.from_dict(data)


def test_create_device_applies_only_valid_profile_without_network(
    descriptor: DeviceDescriptor,
) -> None:
    """Construction consumes known inputs and restores only a matching hint."""
    credentials = DeviceCredentials(token="AA", key="BB")
    profile = DiscoveryProfile(descriptor=descriptor, message_protocol_version=2)
    with (
        patch("midealocal.device.MideaDevice.restore_discovery_profile") as restore,
        patch("socket.socket") as socket,
    ):
        device = create_device(descriptor, credentials, profile)
        restore.assert_called_once_with(profile)
        assert isinstance(device, MideaACDevice)
        assert device.attributes["mode"] == 0
        socket.assert_not_called()
    assert "AA" not in repr(credentials)
    assert "BB" not in repr(credentials)


def test_create_device_ignores_expired_profile(descriptor: DeviceDescriptor) -> None:
    """An expired cache falls back to ordinary device construction."""
    profile = DiscoveryProfile(
        descriptor=descriptor,
        message_protocol_version=2,
        created_at=1,
    )
    with patch("midealocal.device.MideaDevice.restore_discovery_profile") as restore:
        create_device(descriptor, DeviceCredentials(token="AA", key="BB"), profile)
        restore.assert_not_called()


def test_create_device_rejects_unsupported_type(descriptor: DeviceDescriptor) -> None:
    """The new typed entry point fails explicitly for unsupported device types."""
    with pytest.raises(ValueError, match="Unsupported device type"):
        create_device(
            replace(descriptor, device_type=DeviceType.X00),
            DeviceCredentials(token="AA", key="BB"),
        )


def test_restore_and_export_preserve_profile_age_and_exclude_live_state(
    descriptor: DeviceDescriptor,
) -> None:
    """Restoring a hint cannot renew its TTL or populate a new device's state."""
    device = MideaDevice(
        **descriptor.to_dict(),
        attributes={},
        token="AA",
        key="BB",
    )
    assert device.export_discovery_profile() is None
    profile = DiscoveryProfile(
        descriptor=descriptor,
        message_protocol_version=2,
        created_at=1000,
    )
    with patch("midealocal.device_info.time.time", return_value=1001):
        assert device.restore_discovery_profile(profile)
        assert device.export_discovery_profile() == profile
    assert device.attributes == {}
    assert device._message_protocol_version == 2
    assert not device._appliance_query


@pytest.mark.parametrize("active_field", ["_socket", "_is_run"])
def test_running_device_rejects_profile_restore(
    descriptor: DeviceDescriptor,
    active_field: str,
) -> None:
    """Restoring cached metadata must not change an active session's protocol."""
    device = MideaDevice(**descriptor.to_dict(), attributes={}, token="AA", key="BB")
    setattr(device, active_field, True)
    profile = DiscoveryProfile(descriptor=descriptor, message_protocol_version=2)
    assert not device.restore_discovery_profile(profile)
    assert device._message_protocol_version == 0


def test_appliance_reply_confirms_profile_timestamp(
    descriptor: DeviceDescriptor,
) -> None:
    """Only receiving a real protocol reply establishes the cache timestamp."""
    device = MideaDevice(**descriptor.to_dict(), attributes={}, token="AA", key="BB")
    response = bytearray(20)
    response[2] = DeviceType.AC
    response[8] = 2
    response[9] = MessageType.query_appliance
    with patch("midealocal.device.time.time", return_value=1000):
        device.pre_process_message(response)
    with patch("midealocal.device.time.time", return_value=1001):
        profile = device.export_discovery_profile()
    assert profile is not None
    assert profile.created_at == 1000
    assert profile.message_protocol_version == 2
