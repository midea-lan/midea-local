"""CRC8 Test"""

from midealocal.crc8 import calculate


def test_calculate() -> None:
    """Test calculate method."""
    data: bytearray = bytearray(
        [
            0x5A,
            0x82,
            0x01,
            0x11,
            0xFF,
            0x20,
        ],
    )
    assert calculate(data) == 101
