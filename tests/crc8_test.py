"""CRC8 Test"""

from midealocal.crc8 import calculate


def test_calculate() -> None:
    """Test calculate method."""
    data: bytearray = bytearray(
        [
            # 2 bytes - StaicHeader
            0x5A,
            0x5A,
            # 2 bytes - mMessageType
            0x01,
            0x11,
            # 2 bytes - PacketLenght
            0x00,
            0x00,
            # 2 bytes
            0x20,
            0x00,
            # 4 bytes - MessageId
            0x00,
            0x00,
            0x00,
            0x00,
            # 8 bytes - Date&Time
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            # 6 bytes - mDeviceID
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            # 12 bytes
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
        ]
    )
    assert calculate(data) == 86
