"""Confirmed AC operations use one command and fresh query replies."""

from itertools import count
from unittest.mock import MagicMock, patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.crc8 import calculate
from midealocal.device import MessageResult
from midealocal.devices.ac import MideaACDevice
from midealocal.devices.ac.message import MessageGeneralSet, MessageQuery
from midealocal.message import MessageBase, MessageType


def c0_reply(
    message_id: int | None,
    temperature: int,
    *,
    crc_valid: bool = True,
) -> bytes:
    """Build a query reply with a protocol ID and CRC trailer."""
    body = bytearray(23)
    body[0] = 0xC0
    body[1] = 1
    body[2] = (2 << 5) | (temperature - 16)
    body[3] = 60
    if message_id is not None:
        body.append(message_id)
        body.append(calculate(body) ^ (not crc_valid))
    header = bytearray(
        [0xAA, len(body) + 10, 0xAC, 0, 0, 0, 0, 0, 2, MessageType.query],
    )
    packet = header + body
    packet.append(MessageBase.checksum(packet[1:]))
    return bytes(packet)


def record_control_reply(device: MideaACDevice) -> None:
    """Provide decoded state for tests of command orchestration, not frame parsing."""
    assert device._sent_control_query_id is not None
    device._correlated_control_state = (
        device._sent_control_query_id,
        dict(device._attributes),
    )


def test_control_read_rejects_late_reply_and_preserves_matching_snapshot(
    device: MideaACDevice,
) -> None:
    """A polling reply or a later stale frame cannot supply the command snapshot."""
    with patch.object(device, "build_send") as send:
        receptions = iter(["late", "matching_then_late"])

        def receive(_data: bytes) -> MessageResult:
            query_id = send.call_args.args[0]._message_id
            old_id = (query_id + 1) % 254
            if next(receptions) == "late":
                device.process_message(c0_reply(old_id, 26))
            else:
                device.process_message(c0_reply(query_id, 24))
                device.process_message(c0_reply(old_id, 27))
            return MessageResult.SUCCESS

        with patch.object(device, "parse_message", side_effect=receive) as parse:
            state = device._read_control_state()
    assert parse.call_count == 2
    assert state["target_temperature"] == 24
    assert device.supports_confirmed_controls


@pytest.mark.parametrize("reply_kind", ["wrong_id", "no_id", "bad_crc", "set_ack"])
def test_uncorrelated_state_cannot_authorize_a_set(
    device: MideaACDevice,
    reply_kind: str,
) -> None:
    """Missing, damaged, old, or SET replies cannot replace a matching state query."""

    def receive(_data: bytes) -> MessageResult:
        query_id = device._sent_control_query_id
        assert query_id is not None
        if reply_kind == "wrong_id":
            query_id = (query_id + 1) % 254
        raw = bytearray(
            c0_reply(
                None if reply_kind == "no_id" else query_id,
                24,
                crc_valid=reply_kind != "bad_crc",
            ),
        )
        if reply_kind == "set_ack":
            raw[9] = MessageType.set
            raw[-1] = MessageBase.checksum(raw[1:-1])
        device.process_message(bytes(raw))
        return MessageResult.SUCCESS

    with (
        patch.object(device, "build_send") as send,
        patch.object(device, "parse_message", side_effect=receive),
        patch("midealocal.devices.ac.time.monotonic", side_effect=count(0, 0.25)),
        pytest.raises(TimeoutError),
    ):
        device.set_attributes({"target_temperature": 24}).result()
    assert all(isinstance(call.args[0], MessageQuery) for call in send.call_args_list)
    assert not device.supports_confirmed_controls


def test_delayed_matching_values_do_not_confirm_a_new_command(
    device: MideaACDevice,
) -> None:
    """A previous request's target-valued reply must not confirm the current SET."""
    events = iter(["before", "old_matching", "current_stale", "applied"])
    with patch.object(device, "build_send") as send:

        def receive(_data: bytes) -> MessageResult:
            event = next(events)
            query_id = send.call_args.args[0].message_id
            temperature = 24
            if event == "old_matching":
                query_id = send.call_args_list[0].args[0].message_id
                temperature = 27
            elif event == "applied":
                temperature = 27
            device.process_message(c0_reply(query_id, temperature))
            return MessageResult.SUCCESS

        with (
            patch.object(device, "parse_message", side_effect=receive),
            patch("midealocal.devices.ac.time.sleep"),
        ):
            assert device.set_attributes({"target_temperature": 27}).result() == {
                "target_temperature": 27,
            }
    assert (
        sum(isinstance(call.args[0], MessageQuery) for call in send.call_args_list) == 3
    )
    assert (
        sum(isinstance(call.args[0], MessageGeneralSet) for call in send.call_args_list)
        == 1
    )


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
        record_control_reply(device)
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


@pytest.mark.parametrize("connected", [False, True])
def test_prompt_tone_is_local_while_running(
    device: MideaACDevice,
    connected: bool,
) -> None:
    """Offline or busy receivers must not prevent a local preference update."""
    device._is_run = True
    if not connected:
        device._socket = None
    with (
        patch.object(device, "submit_operation") as submit,
        patch.object(device, "update_all") as update,
    ):
        device.set_attribute("prompt_tone", False)
    submit.assert_not_called()
    update.assert_called_once_with({"prompt_tone": False})
    assert device.attributes["prompt_tone"] is False


def test_mode_off_preserves_mode_and_confirms_power(device: MideaACDevice) -> None:
    """An off device retains its cooling mode in its reported state."""
    device._attributes.update({"power": False, "mode": 2})
    with (
        patch.object(
            device,
            "_read_control_state",
            return_value=dict(device._attributes),
        ),
        patch.object(device, "build_send") as send,
        patch("midealocal.devices.ac.time.monotonic", side_effect=count(0, 1)),
        patch("midealocal.devices.ac.time.sleep"),
    ):
        assert device.set_attributes({"mode": 0}).result() == {"power": False}
    assert send.call_args.args[0].mode == 2
    assert send.call_args.args[0].power is False


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
            record_control_reply(device)
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
        record_control_reply(device)
        return MessageResult.SUCCESS

    with (
        patch.object(device, "parse_message", side_effect=receive),
        patch.object(
            device,
            "build_send",
        ) as send,
        patch("midealocal.devices.ac.time.sleep"),
        pytest.raises(TimeoutError),
        patch("midealocal.devices.ac.time.monotonic", side_effect=count(0, 0.25)),
    ):
        device.set_attributes({"target_temperature": 27}).result()
    assert (
        sum(isinstance(call.args[0], MessageGeneralSet) for call in send.call_args_list)
        == 1
    )
    assert not device._unsupported_protocol


def test_confirmation_allows_state_to_settle_within_deadline(
    device: MideaACDevice,
) -> None:
    """Several quick stale replies must not exhaust the time allowed to apply a SET."""
    temperatures = iter([26, 26, 26, 26, 26, 24])

    def receive(_data: bytes) -> MessageResult:
        device._attributes["target_temperature"] = next(temperatures)
        device._control_status_version += 1
        record_control_reply(device)
        return MessageResult.SUCCESS

    with (
        patch.object(device, "parse_message", side_effect=receive),
        patch.object(device, "build_send") as send,
        patch("midealocal.devices.ac.time.sleep"),
        patch("midealocal.devices.ac.time.monotonic", side_effect=count(0, 0.05)),
    ):
        assert device.set_attributes({"target_temperature": 24}).result() == {
            "target_temperature": 24,
        }
    assert (
        sum(isinstance(call.args[0], MessageGeneralSet) for call in send.call_args_list)
        == 1
    )


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
