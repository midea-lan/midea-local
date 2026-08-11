"""Regression tests for subtype-395 review findings."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ed import DeviceAttributes, MideaEDDevice
from midealocal.devices.ed.message import MessageEDResponse
from midealocal.message import ListTypes

TEST_AUTH_VALUE = "AA"


@pytest.mark.parametrize("reported_keep_warm_time", [None, 12.0])
def test_tea_bar_keep_warm_uses_device_default_duration(
    reported_keep_warm_time: float | None,
) -> None:
    """Do not send an explicit duration for the appliance's 12-hour default."""
    tea_bar = MideaEDDevice(
        name="Tea Bar",
        device_id=2,
        ip_address="192.0.2.1",
        port=6444,
        token=TEST_AUTH_VALUE,
        key="BB",
        device_protocol=ProtocolVersion.V3,
        model="63000622",
        subtype=395,
        customize="",
    )
    tea_bar._attributes[DeviceAttributes.keep_warm_time] = reported_keep_warm_time

    with patch.object(tea_bar, "build_send") as mock_build_send:
        tea_bar.set_attribute(DeviceAttributes.keep_warm, True)

    message = mock_build_send.call_args.args[0]
    assert message.body == bytearray(
        [0x15, 0x01, 0x01, 0x08, 0x04, 0x01, 0x00, 0x00],
    )


@pytest.mark.parametrize("body_size", [3, 8])
def test_tea_bar_short_x15_acknowledgement_is_not_status_parsed(
    body_size: int,
) -> None:
    """Keep short subtype-395 X15 acknowledgements without body-06 parsing."""
    header = bytearray(
        [
            0xAA,
            0x00,
            0xED,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x01,
            0x02,
        ],
    )
    body = bytearray(body_size)
    body[0] = ListTypes.X15

    message = MessageEDResponse(bytes(header + body + bytearray([0x00])), subtype=395)

    assert message.body_type == ListTypes.X15
    assert not hasattr(message, "current_temperature")
    assert not hasattr(message, "fault_code")
