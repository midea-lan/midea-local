"""Network latency regressions using fragmented and delayed replies."""

import asyncio
from unittest.mock import AsyncMock, patch

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import AuthException, MideaDevice
from midealocal.discover import discover, get_device_info
from tests.conftest import make_stream_pair
from tests.discover_test import (
    DEVICE_IP,
    SN_TYPE1,
    V1_XML,
    _build_id_response,
    _build_v2_packet,
    _fake_loop,
)


@pytest.fixture
def device() -> MideaDevice:
    """Build an offline device without real credentials."""
    return MideaDevice(
        device_type=DeviceType.AC,
        attributes={},
        name="test",
        device_id=1,
        ip_address=DEVICE_IP,
        port=6444,
        token="",
        key="",
        device_protocol=ProtocolVersion.V3,
        model="test",
        subtype=0,
    )


@pytest.mark.asyncio
async def test_fragmented_handshake_keeps_following_frame(device: MideaDevice) -> None:
    """TCP fragments assemble once; following status bytes remain unread."""
    reader = asyncio.StreamReader()
    _, writer = make_stream_pair()
    device._reader, device._writer = reader, writer
    frame = b"\x83\x70\x00\x40\x20\x01\x00\x00" + bytes(64)

    async def feed() -> None:
        for chunk in (frame[:3], frame[3:15], frame[15:] + b"next"):
            reader.feed_data(chunk)
            await asyncio.sleep(0)

    feeder = asyncio.create_task(feed())
    try:
        with patch.object(device._security, "tcp_key") as key:
            await device.authenticate()
        key.assert_called_once_with(bytes(64), b"")
        assert await reader.read(4) == b"next"
    finally:
        await feeder


@pytest.mark.asyncio
async def test_handshake_eof_is_auth_failure(device: MideaDevice) -> None:
    """A truncated header must not wait for the entire auth timeout."""
    reader = asyncio.StreamReader()
    reader.feed_data(b"\x83\x70")
    reader.feed_eof()
    device._reader, device._writer = reader, make_stream_pair()[1]
    with pytest.raises(AuthException):
        await device.authenticate()


def test_invalid_v2_length_rejected() -> None:
    """A declared length smaller than the envelope cannot consume a valid frame."""
    with pytest.raises(ValueError, match="V2 frame length"):
        MideaDevice.fetch_v2_message(b"\x5a\x5a\x00\x00\x01\x00")


@pytest.mark.asyncio
async def test_legacy_discovery_probes_each_endpoint_once() -> None:
    """Duplicate UDP responses must not repeat the legacy TCP lookup."""
    reply = (V1_XML % SN_TYPE1, (DEVICE_IP, 6445))
    loop = _fake_loop(recvfrom_side_effect=[reply, reply, TimeoutError])
    with (
        patch("midealocal.discover.asyncio.get_running_loop", return_value=loop),
        patch("midealocal.discover.enum_all_broadcast", return_value=[]),
        patch(
            "midealocal.discover.get_device_info",
            new=AsyncMock(return_value=_build_id_response()),
        ) as info,
    ):
        result = await discover()
    assert len(result) == 1
    info.assert_awaited_once()


@pytest.mark.asyncio
async def test_discovery_budget_is_not_restarted_by_traffic() -> None:
    """An expired scan returns already found devices without another UDP read."""
    loop = _fake_loop(recvfrom_side_effect=[(_build_v2_packet(), (DEVICE_IP, 6445))])
    # No sends; deadline=5, first receive at t=0, second attempted at t=6.
    loop.time = iter([0.0, 0.0, 6.0]).__next__
    with (
        patch("midealocal.discover.asyncio.get_running_loop", return_value=loop),
        patch("midealocal.discover.enum_all_broadcast", return_value=[]),
    ):
        result = await discover()
    assert len(result) == 1
    loop.sock_recvfrom.assert_awaited_once()


@pytest.mark.asyncio
async def test_handshake_timeout_covers_all_fragments(device: MideaDevice) -> None:
    """A stalled payload cannot restart the authentication budget."""
    reader = asyncio.StreamReader()
    reader.feed_data(b"\x83\x70\x00\x40\x20\x01\x00\x00")
    device._reader, device._writer = reader, make_stream_pair()[1]
    with patch("midealocal.device.SOCKET_TIMEOUT", 0), pytest.raises(TimeoutError):
        await device.authenticate()


@pytest.mark.asyncio
async def test_timer_deadline_and_refresh_completion(device: MideaDevice) -> None:
    """Short refresh intervals wake promptly and slow work schedules from completion."""
    device._previous_refresh = device._previous_heartbeat = 100
    device._refresh_interval = 2
    with patch.object(asyncio.get_running_loop(), "time", return_value=101):
        assert device._next_timer_delay() == 1
    with (
        patch.object(asyncio.get_running_loop(), "time", return_value=110),
        patch.object(device, "refresh_status", new=AsyncMock()),
    ):
        await device._check_refresh(102)
    assert device._previous_refresh == 110


@pytest.mark.asyncio
async def test_device_info_drain_is_bounded_and_closed() -> None:
    """A writer stuck in drain is covered by the same information-query budget."""
    reader, writer = make_stream_pair()

    async def block() -> None:
        await asyncio.Future()

    writer.drain.side_effect = block
    with (
        patch(
            "midealocal.discover.asyncio.open_connection",
            new=AsyncMock(return_value=(reader, writer)),
        ),
        patch("midealocal.discover.DEVICE_INFO_TIMEOUT", 0),
    ):
        assert await get_device_info(DEVICE_IP, 6444) == bytearray()
    writer.close.assert_called_once()
