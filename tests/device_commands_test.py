"""Command operations share the device thread's sole socket reader."""

import socket
import threading
from collections.abc import Iterator
from concurrent.futures import wait
from unittest.mock import MagicMock, patch

import pytest

from midealocal.const import DeviceType, ProtocolVersion
from midealocal.device import QUERY_TIMEOUT, MideaDevice
from midealocal.exceptions import SocketException


@pytest.fixture
def device() -> Iterator[MideaDevice]:
    """Build an offline device and always clean up its worker."""
    appliance = MideaDevice(
        device_type=DeviceType.AC,
        attributes={},
        name="command-test",
        device_id=1,
        ip_address="127.0.0.1",
        port=0,
        token="",
        key="",
        device_protocol=ProtocolVersion.V2,
        model="",
        subtype=0,
    )
    yield appliance
    appliance.close()
    if appliance.ident is not None:
        appliance.join(timeout=2)
        assert not appliance.is_alive()


def test_submit_before_open_returns_completed_future(device: MideaDevice) -> None:
    """Synchronous callers can use the same Future API without a worker."""
    future = device.submit_operation(lambda: 42)
    assert future.done()
    assert future.result() == 42


def test_submit_captures_callback_exception(device: MideaDevice) -> None:
    """The Future reports an operation failure without throwing on submit."""

    def fail() -> None:
        raise ValueError("operation failed")

    future = device.submit_operation(fail)
    with pytest.raises(ValueError, match="operation failed"):
        future.result()


def test_submit_wakes_receiver_and_owns_command_reply(device: MideaDevice) -> None:
    """A blocked receiver wakes promptly and cannot consume its own command's reply."""
    client, peer = socket.socketpair()
    device._socket = client
    device.set_refresh_interval(0)
    device._heartbeat_interval = 3600
    entered_receive = threading.Event()
    real_recv = device._receive_message

    def recv(timeout: float) -> bytes | None:
        entered_receive.set()
        return real_recv(timeout)

    with peer, patch.object(device, "_receive_message", side_effect=recv):
        device.open()
        assert entered_receive.wait(timeout=1)

        def command() -> tuple[int | None, bytes]:
            client.sendall(b"query")
            peer.sendall(b"reply")
            return threading.current_thread().ident, client.recv(5)

        future = device.submit_operation(command)
        assert future.result(timeout=1) == (device.ident, b"reply")
        assert peer.recv(5) == b"query"
        device.close()
        device.join(timeout=1)
        assert not device.is_alive()


def test_close_finishes_queued_and_running_operations(device: MideaDevice) -> None:
    """Shutdown settles Futures even while an operation is still unwinding."""
    client, peer = socket.socketpair()
    device._socket = client
    entered = threading.Event()
    release = threading.Event()

    def blocking_operation() -> None:
        entered.set()
        release.wait(timeout=2)

    with peer:
        device.open()
        running = device.submit_operation(blocking_operation)
        try:
            assert entered.wait(timeout=1)
            queued = device.submit_operation(lambda: "must not run")
            device.close()
            for future in (running, queued):
                with pytest.raises(SocketException):
                    future.result(timeout=1)
        finally:
            release.set()


def test_closed_device_rejects_new_operation(device: MideaDevice) -> None:
    """A closed worker must not fall back to synchronous socket reads."""
    device.close()
    with pytest.raises(SocketException):
        device.submit_operation(lambda: "must not run").result()


def test_failed_worker_start_closes_wakeup_channels(device: MideaDevice) -> None:
    """A failed Thread.start must not leave a queue with no consumer."""
    with (
        patch("threading.Thread.start", side_effect=RuntimeError("cannot start")),
        pytest.raises(RuntimeError, match="cannot start"),
    ):
        device.open()
    assert not device._is_run
    assert device._wakeup_reader is not None
    assert device._wakeup_reader.fileno() == -1
    assert device._wakeup_writer is not None
    assert device._wakeup_writer.fileno() == -1
    with pytest.raises(SocketException):
        device.submit_operation(lambda: "must not run").result()


def test_control_readiness_defers_full_discovery(device: MideaDevice) -> None:
    """Control readiness advertises availability before the background window."""
    with (
        patch("midealocal.device.socket.socket"),
        patch.object(device, "_refresh_control_status", return_value=True),
        patch.object(device, "refresh_status") as refresh,
        patch("midealocal.device.time.monotonic", return_value=20),
    ):
        assert device.connect(True, readiness="control")
        assert device.available
        assert not bool(device.discovery_complete)
        refresh.assert_not_called()
        device._check_discovery(20)
        refresh.assert_called_once_with(False)
        assert device._discovery_deadline == 20 + QUERY_TIMEOUT
    updates = MagicMock()
    device.register_update(updates)
    device._is_run = True
    device._check_discovery(20 + QUERY_TIMEOUT)
    assert bool(device.discovery_complete)
    updates.assert_called_once_with({"discovery_complete": True})
    device.close_socket()
    assert not bool(device.discovery_complete)
    assert device._discovery_deadline is None


def test_default_control_hook_finishes_full_discovery(device: MideaDevice) -> None:
    """Devices without a minimal query keep their established full probe."""
    with (
        patch("midealocal.device.socket.socket"),
        patch.object(device, "refresh_status") as refresh,
    ):
        assert device.connect(True, readiness="control")
        refresh.assert_called_once_with(True)
    assert device.discovery_complete


def test_running_thread_rejects_self_submission(device: MideaDevice) -> None:
    """An update callback cannot block waiting for work queued to itself."""
    client, peer = socket.socketpair()
    device._socket = client
    with peer:
        device.open()
        result = device.submit_operation(
            lambda: device.submit_operation(lambda: "nested").result(),
        )
        with pytest.raises(RuntimeError, match="device thread"):
            result.result(timeout=1)


def test_cancelled_operation_never_runs(device: MideaDevice) -> None:
    """Cancelled queued work is skipped and concurrent.futures.wait is notified."""
    client, peer = socket.socketpair()
    device._socket = client
    entered = threading.Event()
    release = threading.Event()

    def block() -> None:
        entered.set()
        release.wait(timeout=2)

    with peer:
        device.open()
        blocker = device.submit_operation(block)
        try:
            assert entered.wait(timeout=1)
            callback = MagicMock()
            cancelled = device.submit_operation(callback)
            assert cancelled.cancel()
        finally:
            release.set()
        blocker.result(timeout=1)
        done, pending = wait([cancelled], timeout=1)
        assert done == {cancelled}
        assert not pending
        callback.assert_not_called()


def test_queue_capacity_and_connection_failure(device: MideaDevice) -> None:
    """Disconnected or overloaded devices fail promptly instead of queuing forever."""
    device._is_run = True
    with pytest.raises(SocketException, match="not connected"):
        device.submit_operation(lambda: None).result()
    device._socket = MagicMock()
    callback = MagicMock()
    with patch("midealocal.device.MAX_PENDING_OPERATIONS", 1):
        pending = device.submit_operation(callback)
        with pytest.raises(RuntimeError, match="queue is full"):
            device.submit_operation(callback).result()
    device.close_socket()
    with pytest.raises(SocketException, match="connection closed"):
        pending.result(timeout=1)
    callback.assert_not_called()


def test_close_notifies_waiters_for_cancelled_pending_work(device: MideaDevice) -> None:
    """Removing cancelled work during shutdown still notifies Future waiters."""
    device._is_run = True
    device._socket = MagicMock()
    cancelled = device.submit_operation(lambda: None)
    assert cancelled.cancel()
    device.close()
    done, pending = wait([cancelled], timeout=0)
    assert done == {cancelled}
    assert not pending


def test_commands_take_priority_over_background_probe(device: MideaDevice) -> None:
    """A queued control operation runs before optional discovery is started."""
    device._is_run = True
    device._socket = MagicMock()
    device._discovery_pending = True
    pending = device.submit_operation(lambda: None)
    with patch.object(device, "refresh_status") as refresh:
        device._check_discovery(0)
        refresh.assert_not_called()
    assert not pending.done()
    device._discovery_deadline = 3
    device._previous_refresh = device._previous_heartbeat = 0
    with patch("midealocal.device.time.monotonic", return_value=0):
        assert device._next_receive_timeout(0) == 3


@pytest.mark.parametrize("error", [ConnectionResetError, SocketException, TimeoutError])
def test_operation_connection_errors_fail_pending_without_replay(
    device: MideaDevice,
    error: type[Exception],
) -> None:
    """Broken transports fail queued commands; a confirmation timeout does not."""
    device._is_run = True
    sock = MagicMock()
    device._socket = sock
    failed = MagicMock(side_effect=error("failed"))
    first = device.submit_operation(failed)
    second_callback = MagicMock()
    second = device.submit_operation(second_callback)
    device._execute_operation(*device._operations.popleft())
    with pytest.raises(error):
        first.result()
    failed.assert_called_once()
    second_callback.assert_not_called()
    if error is TimeoutError:
        assert not second.done()
        assert device._socket is sock
    else:
        assert not bool(device._socket)
        with pytest.raises(SocketException):
            second.result()
