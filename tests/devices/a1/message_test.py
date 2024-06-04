"""Test a1 message"""

import unittest
from midealocal.devices.a1.message import (
    MessageA1Base,
    MessageQuery,
    MessageNewProtocolQuery,
    MessageSet,
    MessageNewProtocolSet,
    NewProtocolTags,
)


class TestMessageA1Base(unittest.TestCase):
    """Test A1 Message Base."""

    def test_message_id_increment(self) -> None:
        """Test message Id Increment."""
        msg1 = MessageA1Base(protocol_version=1, message_type=1, body_type=1)
        msg2 = MessageA1Base(protocol_version=1, message_type=1, body_type=1)
        self.assertEqual(msg2._message_id, msg1._message_id + 1)

    def test_body_not_implemented(self) -> None:
        """Test body not implemented."""
        msg = MessageA1Base(protocol_version=1, message_type=1, body_type=1)
        with self.assertRaises(NotImplementedError):
            _ = msg.body


class TestMessageQuery(unittest.TestCase):
    """Test Message Query."""

    def test_query_body(self) -> None:
        """Test query body"""
        query = MessageQuery(protocol_version=1)
        expected_body = bytearray(
            [
                0x41,
                0x81,
                0x00,
                0xFF,
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
                0x00,
                0x00,
                0x00,
                0x00,
            ]
        )
        self.assertEqual(query.body[:-2], expected_body)


class TestMessageNewProtocolQuery(unittest.TestCase):
    """Test Message New Protocol Query."""

    def test_new_protocol_query_body(self) -> None:
        """Test new protocol query body"""
        query = MessageNewProtocolQuery(protocol_version=1)
        expected_body = bytearray(
            [0xB1, 1, NewProtocolTags.light & 0xFF, NewProtocolTags.light >> 8]
        )
        self.assertEqual(query.body[:-2], expected_body)


class TestMessageSet(unittest.TestCase):
    """Test Message Set."""

    def test_set_body(self) -> None:
        """Test set body."""
        msg_set = MessageSet(protocol_version=1)

        expected_body = bytearray([msg_set.body_type]) + bytearray(
            [
                msg_set.power | msg_set.prompt_tone | 0x02,
                msg_set.mode,
                msg_set.fan_speed,
                0x00,
                0x00,
                0x00,
                msg_set.target_humidity,
                msg_set.child_lock,
                msg_set.anion,
                msg_set.swing,
                0x00,
                0x00,
                msg_set.water_level_set,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
                0x00,
            ],
        )
        self.assertEqual(msg_set.body[:-2], expected_body)


class TestMessageNewProtocolSet(unittest.TestCase):
    """Test Message New Protocol Set."""

    def test_new_protocol_set_body(self) -> None:
        """Test new protocol set body."""
        msg_set = MessageNewProtocolSet(protocol_version=1)
        msg_set.light = True
        expected_body = bytearray(b"\xb0\x01[\x00\x01\x01")
        self.assertEqual(msg_set.body[:-2], expected_body)
