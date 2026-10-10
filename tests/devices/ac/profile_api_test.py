"""AC discovery profile boundaries and connection readiness tests."""

import json
from collections.abc import Iterator
from dataclasses import replace
from unittest.mock import MagicMock, patch

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.device import MessageResult
from midealocal.device_info import PROFILE_MAX_AGE, DiscoveryProfile
from midealocal.devices.ac import DeviceAttributes, MideaACDevice
from midealocal.devices.ac.message import (
    MessageCapabilitiesAdditionalQuery,
    MessageCapabilitiesQuery,
    MessageQuery,
)
from midealocal.message import MessageBase, MessageType


def _device() -> MideaACDevice:
    return MideaACDevice(
        name="Office",
        device_id=123,
        ip_address="192.0.2.10",
        port=6444,
        token="AA",
        key="BB",
        device_protocol=ProtocolVersion.V3,
        model="22012297",
        subtype=1,
        customize="",
    )


def _response(body: bytearray) -> bytes:
    header = bytearray([0xAA, 0, DeviceType.AC, 0, 0, 0, 0, 0, 2, MessageType.query])
    header[1] = len(header) + len(body)
    frame = header + body
    frame.append(MessageBase.checksum(frame[1:]))
    return bytes(frame)


def _b5_body(message_id: int, *, eco: bool = True) -> bytearray:
    body = bytearray([0xB5, 2, 0x12, 0x02, 1, int(eco)])
    body += bytearray([0x25, 0x02, 7, 32, 60, 32, 60, 32, 60, 0])
    body += bytearray([0, message_id])
    body.append(calculate(body))
    return body


@pytest.fixture
def confirmed_device() -> Iterator[MideaACDevice]:
    """Confirm the protocol and both capability pages through actual parsers."""
    device = _device()
    appliance = bytearray(20)
    appliance[2] = DeviceType.AC
    appliance[8] = 2
    appliance[9] = MessageType.query_appliance
    with patch("midealocal.device.time.time", return_value=1000):
        device.pre_process_message(appliance)
        for query in (
            MessageCapabilitiesQuery(2),
            MessageCapabilitiesAdditionalQuery(2),
        ):
            with patch("midealocal.device.MideaDevice.build_send"):
                device.build_send(query, query=True)
            device.process_message(_response(_b5_body(query.message_id)))
    with patch("midealocal.device_info.time.time", return_value=1001):
        yield device


def test_ac_profile_roundtrip_restores_metadata_without_control_state(
    confirmed_device: MideaACDevice,
) -> None:
    """Confirmed capabilities survive JSON, while live setpoints and power do not."""
    confirmed_device._attributes[DeviceAttributes.power] = True
    confirmed_device._attributes[DeviceAttributes.mode] = 5
    confirmed_device._attributes[DeviceAttributes.target_temperature] = 28
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    assert profile.capability_pages == (0, 1)
    assert profile.capabilities["eco"] is True
    document = json.loads(json.dumps(profile.to_dict()))
    assert "attributes" not in document
    assert "token" not in document
    assert "key" not in document
    restored = _device()
    assert restored.restore_discovery_profile(DiscoveryProfile.from_dict(document))
    assert restored.export_discovery_profile() == profile
    assert restored.attributes[DeviceAttributes.power] is False
    assert restored.attributes[DeviceAttributes.mode] == 0
    assert restored.attributes[DeviceAttributes.target_temperature] == 24
    assert restored.attributes[DeviceAttributes.min_temperature] == 16
    assert restored.attributes[DeviceAttributes.max_temperature] == 30
    assert restored._control_status_version == 0
    assert restored._pending_capability_pages == {}


@pytest.mark.parametrize("changed_field", ["device_id", "model", "subtype"])
def test_ac_profile_rejects_identity_mismatch_without_partial_restore(
    confirmed_device: MideaACDevice,
    changed_field: str,
) -> None:
    """Invalid identities cannot alter protocol hints or capability-derived state."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    changes: dict = {changed_field: "different" if changed_field == "model" else 999}
    profile = replace(
        profile,
        descriptor=replace(profile.descriptor, **changes),
    )
    restored = _device()
    initial = dict(restored.attributes)
    assert not restored.restore_discovery_profile(profile)
    assert restored.attributes == initial
    assert restored._appliance_query
    assert restored.export_discovery_profile() is None


def test_ac_profile_expiry_and_reexport_do_not_renew_old_timestamp(
    confirmed_device: MideaACDevice,
) -> None:
    """Repeated restore/export cycles preserve the original discovery lifetime."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    with patch(
        "midealocal.device_info.time.time",
        return_value=1000 + PROFILE_MAX_AGE - 1,
    ):
        restored = _device()
        assert restored.restore_discovery_profile(profile)
        exported = restored.export_discovery_profile()
        assert exported is not None
        assert exported.created_at == 1000
    with patch("midealocal.device_info.time.time", return_value=1000 + PROFILE_MAX_AGE):
        assert not _device().restore_discovery_profile(exported)


@pytest.mark.parametrize("reply_kind", ["unsolicited", "wrong_id", "bad_crc"])
def test_ac_profile_exports_only_confirmed_b5_metadata(
    confirmed_device: MideaACDevice,
    reply_kind: str,
) -> None:
    """An unsolicited, unrelated, or invalid reply cannot replace cached metadata."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    query = MessageCapabilitiesQuery(2)
    if reply_kind != "unsolicited":
        with patch("midealocal.device.MideaDevice.build_send"):
            confirmed_device.build_send(query, query=True)
    message_id = query.message_id
    if reply_kind == "wrong_id":
        message_id = (message_id + 1) % 256
    body = _b5_body(message_id, eco=False)
    if reply_kind == "bad_crc":
        body[-1] ^= 1
    confirmed_device.process_message(_response(body))
    assert confirmed_device._capabilities["eco"] is False
    assert confirmed_device.export_discovery_profile() == profile


def test_control_connection_preserves_profile_pages_but_reads_fresh_state(
    confirmed_device: MideaACDevice,
) -> None:
    """A control-ready connection skips cached discovery but obtains fresh C0 state."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    restored = _device()
    assert restored.restore_discovery_profile(profile)
    body = bytearray(23)
    body[0] = 0xC0
    body[1] = 1
    body[2] = (5 << 5) | 10
    body[3] = 60

    def parse(_data: bytes) -> MessageResult:
        restored.process_message(_response(body))
        return MessageResult.SUCCESS

    sock = MagicMock()
    sock.recv.return_value = b"fresh state"
    with (
        patch("midealocal.device.socket.socket", return_value=sock),
        patch.object(restored, "authenticate"),
        patch("midealocal.device.MideaDevice.build_send") as send,
        patch.object(restored, "parse_message", side_effect=parse),
    ):
        assert restored.connect(True, readiness="control")
    assert [type(call.args[0]) for call in send.call_args_list] == [MessageQuery]
    assert restored._control_status_version == 1
    assert restored.attributes[DeviceAttributes.mode] == 5
    assert restored.export_discovery_profile() == profile
    assert restored._discovery_pending


def test_full_connection_explicitly_reprobes_restored_capability_pages(
    confirmed_device: MideaACDevice,
) -> None:
    """A full probe resends cached pages and clears prior confirmations."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    restored = _device()
    assert restored.restore_discovery_profile(profile)
    with (
        patch("midealocal.device.socket.socket"),
        patch.object(restored, "authenticate"),
        patch("midealocal.device.MideaDevice.build_send") as send,
        patch.object(restored, "_wait_for_query_response"),
    ):
        assert restored.connect(True, readiness="full")
    capability_types = {
        type(call.args[0])
        for call in send.call_args_list
        if isinstance(call.args[0], MessageCapabilitiesQuery)
    }
    assert capability_types == {
        MessageCapabilitiesQuery,
        MessageCapabilitiesAdditionalQuery,
    }
    refreshed = restored.export_discovery_profile()
    assert refreshed is not None
    assert refreshed.capability_pages == ()
    assert refreshed.capabilities == {}
    assert refreshed.temperature_limits is None
    assert refreshed.created_at == profile.created_at


def test_replacing_profile_with_protocol_only_drops_previous_capabilities(
    confirmed_device: MideaACDevice,
) -> None:
    """A second accepted restore replaces metadata instead of merging stale pages."""
    profile = confirmed_device.export_discovery_profile()
    assert profile is not None
    restored = _device()
    assert restored.restore_discovery_profile(profile)
    protocol_only = replace(
        profile,
        capability_pages=(),
        capabilities={},
        temperature_limits=None,
    )
    assert restored.restore_discovery_profile(protocol_only)
    assert restored.export_discovery_profile() == protocol_only
    assert restored._capabilities == {}
    assert restored.attributes[DeviceAttributes.min_temperature] is None
    assert restored.attributes[DeviceAttributes.max_temperature] is None
