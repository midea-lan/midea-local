"""Midea local packet builder test."""

from midealocal.packet_builder import PacketBuilder
from midealocal.security import LocalSecurity


class TestPacketBuilder:
    """Test PacketBuilder."""

    def test_finalize_default(self) -> None:
        """Test finalize with the default (encrypted) message type."""
        device_id = 0x1234567890AB
        command = bytearray([0xAA, 0x20, 0xAC] + [0x00] * 10)
        builder = PacketBuilder(device_id, command)
        packet = builder.finalize()

        # static header and message type
        assert packet[:4] == bytes([0x5A, 0x5A, 0x01, 0x11])
        # declared packet length matches the final packet length
        assert int.from_bytes(packet[4:6], "little") == len(packet)
        # device id is embedded little endian
        assert packet[20:28] == device_id.to_bytes(8, "little")
        # trailing 16 bytes are the salted MD5 of the rest of the packet
        assert packet[-16:] == LocalSecurity().encode32_data(packet[:-16])
        # the encrypted command round trips back to the original command
        assert LocalSecurity().aes_decrypt(packet[40:-16]) == command

    def test_finalize_other_message_type(self) -> None:
        """Test finalize with a non-default message type."""
        builder = PacketBuilder(1, bytearray([0xAA]))
        packet = builder.finalize(msg_type=0)

        assert packet[3] == 0x10
        assert packet[6] == 0x7B
        # no encrypted command appended: header (40) + checksum (16) only
        assert len(packet) == 56
        assert int.from_bytes(packet[4:6], "little") == len(packet)
        assert packet[-16:] == LocalSecurity().encode32_data(packet[:-16])

    def test_checksum(self) -> None:
        """Test the static checksum helper."""
        # despite the bytes annotation in the source, an int is returned
        assert PacketBuilder.checksum(bytes([0x01, 0x02, 0x03])) == 0xFA
        assert PacketBuilder.checksum(b"") == 0x00

    def test_packet_time(self) -> None:
        """Test packet time is 8 reversed two-digit values."""
        packet_time = PacketBuilder.packet_time()
        assert len(packet_time) == 8
        assert all(0 <= value <= 99 for value in packet_time)
