"""Confirmed AC operations use one command and fresh query replies."""

from unittest.mock import MagicMock, patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.device import MessageResult
from midealocal.devices.ac import MideaACDevice
from midealocal.devices.ac.message import MessageGeneralSet, MessageQuery


@pytest.fixture
def device() -> MideaACDevice:
    """Create a generic AC with a connected mock transport."""
    result = MideaACDevice(
        name="AC",
        device_id=1,
        ip_address="192.0.2.1",
        port=6444,
        token="",
        key="",
        device_protocol=ProtocolVersion.V2,
        model="test",
        subtype=0,
        customize="",
    )
    result._appliance_query = False
    result._socket = MagicMock()
    result._socket.recv.return_value = b"state"
    return result


def test_combined_control_preserves_fresh_state(device: MideaACDevice) -> None:
    """A fresh read supplies untouched fields; one SET carries both changes."""
    replies = iter(
        [
            {"power": True, "mode": 3, "target_temperature": 26, "fan_speed": 60},
            {"power": True, "mode": 2, "target_temperature": 24, "fan_speed": 102},
        ],
    )

    def receive(_data: bytes) -> MessageResult:
        device._attributes.update(next(replies))
        device._control_status_version += 1
        return MessageResult.SUCCESS

    with (
        patch.object(device, "parse_message", side_effect=receive),
        patch.object(
            device,
            "build_send",
        ) as send,
    ):
        result = device.set_attributes({"mode": 2, "target_temperature": 24}).result()
    commands = [call.args[0] for call in send.call_args_list]
    assert [type(command) for command in commands] == [
        MessageQuery,
        MessageGeneralSet,
        MessageQuery,
    ]
    assert commands[1].fan_speed == 102
    assert commands[1].power is True
    assert commands[1].dry is False
    assert result == {"mode": 2, "target_temperature": 24, "power": True}


def test_confirmation_ignores_ack_and_requeries_stale_status(
    device: MideaACDevice,
) -> None:
    """A SET ACK cannot complete an operation; stale state triggers only queries."""
    events = iter(["before", "ack", "stale", "confirmed"])

    def receive(_data: bytes) -> MessageResult:
        event = next(events)
        if event != "ack":
            device._control_status_version += 1
            device._attributes["target_temperature"] = (
                24 if event == "confirmed" else 26
            )
        return MessageResult.SUCCESS

    with (
        patch.object(device, "parse_message", side_effect=receive),
        patch.object(
            device,
            "build_send",
        ) as send,
        patch("midealocal.devices.ac.time.sleep"),
    ):
        assert device.set_attributes({"target_temperature": 24}).result() == {
            "target_temperature": 24,
        }
    assert (
        sum(isinstance(call.args[0], MessageGeneralSet) for call in send.call_args_list)
        == 1
    )
    assert (
        sum(isinstance(call.args[0], MessageQuery) for call in send.call_args_list) == 3
    )


def test_confirmation_timeout_does_not_resend_set_or_blacklist(
    device: MideaACDevice,
) -> None:
    """Confirmation failure is explicit and does not make the query unsupported."""

    def receive(_data: bytes) -> MessageResult:
        device._control_status_version += 1
        return MessageResult.SUCCESS

    with (
        patch.object(device, "parse_message", side_effect=receive),
        patch.object(
            device,
            "build_send",
        ) as send,
        patch("midealocal.devices.ac.time.sleep"),
        pytest.raises(TimeoutError),
    ):
        device.set_attributes({"target_temperature": 27}).result()
    assert (
        sum(isinstance(call.args[0], MessageGeneralSet) for call in send.call_args_list)
        == 1
    )
    assert not device._unsupported_protocol


@pytest.mark.parametrize(
    ("expected", "reported", "matches"),
    [
        (102, 103, True),
        (80, 79, True),
        (80, 60, False),
        (63, 64, False),
    ],
)
def test_fan_confirmation_uses_existing_named_speed_buckets(
    device: MideaACDevice,
    expected: int,
    reported: int,
    matches: bool,
) -> None:
    """Firmware can report a slightly different value in the commanded fan mode."""
    device._attributes["fan_speed"] = reported
    assert device._control_value_matches("fan_speed", expected) is matches


@pytest.mark.parametrize(
    "changes",
    [
        {"mode": 8},
        {"power": "true"},
        {"target_temperature": float("nan")},
        {"fan_speed": -1},
        {"mode": 2, "not_an_attribute": True},
    ],
)
def test_invalid_changes_never_send(device: MideaACDevice, changes: dict) -> None:
    """Validate the complete request before performing network I/O."""
    with (
        patch.object(device, "build_send") as send,
        pytest.raises(ValueError, match="Invalid basic control"),
    ):
        device.set_attributes(changes).result()
    send.assert_not_called()


def test_control_readiness_defers_optional_probe(device: MideaACDevice) -> None:
    """Ordinary AC readiness waits only for the safe control snapshot."""
    with patch.object(device, "refresh_status_for_set") as refresh:
        assert device._refresh_control_status()
    refresh.assert_called_once_with("power")


def test_special_model_keeps_full_probe(device: MideaACDevice) -> None:
    """Devices without trustworthy C0 state retain their full startup path."""
    device._uses_new_protocol_temperature = True
    with patch.object(device, "refresh_status") as refresh:
        assert not device._refresh_control_status()
    refresh.assert_called_once_with(True)
