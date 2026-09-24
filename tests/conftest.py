"""Shared test fixtures and helpers for the midea-local test suite."""

import asyncio
import contextlib
from collections.abc import AsyncIterator, Sequence
from unittest.mock import AsyncMock, MagicMock

from midealocal.device import MideaDevice


def make_stream_pair(
    reads: Sequence[bytes | bytearray | BaseException] = (),
) -> tuple[AsyncMock, MagicMock]:
    """Build a fake (StreamReader, StreamWriter) pair for device/discover tests.

    ``reads`` scripts successive ``reader.read()`` calls, mirroring how the
    old socket-based tests scripted ``socket.recv()`` via ``side_effect``.
    """
    reader = AsyncMock(spec=asyncio.StreamReader)
    reader.read.side_effect = list(reads)
    writer = MagicMock(spec=asyncio.StreamWriter)
    writer.wait_closed = AsyncMock()
    writer.drain = AsyncMock()
    return reader, writer


@contextlib.asynccontextmanager
async def running_reader_loop(device: MideaDevice) -> AsyncIterator[asyncio.Task]:
    """Run device._read_loop() as a background task for the scope of a test.

    device._reader_task is the sole reader of device._reader (see
    MideaDevice._read_loop's docstring); refresh_status()/_wait_for_query_response()
    only make sense with this task actually running to service their
    self._response_waiter.
    """
    task = asyncio.create_task(device._read_loop())
    device._reader_task = task
    try:
        yield task
    finally:
        device._reader_task = None
        task.cancel()
        with contextlib.suppress(BaseException):
            await task
