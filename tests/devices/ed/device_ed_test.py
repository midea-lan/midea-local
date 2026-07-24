"""Test ED Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.ed import DeviceAttributes, MideaEDDevice
from midealocal.devices.ed.message import (
    MessageEDBase,
    MessageOldSet,
    MessageQuery,
    MessageQuery01,
    MessageQuery04,
    MessageQuery05,
    MessageQuery06,
    MessageQuery07,
    MessageQuery09,
    MessageQueryFF,
)


class TestMideaEDDevice:
    """Test Midea ED Device."""

    device: MideaEDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea ed Device setup."""
        self.device = MideaEDDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=1,
            customize="test_customize",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert not self.device.attributes[DeviceAttributes.power]
        assert self.device.attributes[DeviceAttributes.water_consumption] is None
        assert self.device.attributes[DeviceAttributes.in_tds] is None
        assert self.device.attributes[DeviceAttributes.out_tds] is None
        assert self.device.attributes[DeviceAttributes.filter1] is None
        assert self.device.attributes[DeviceAttributes.filter2] is None
        assert self.device.attributes[DeviceAttributes.filter3] is None
        assert self.device.attributes[DeviceAttributes.life1] is None
        assert self.device.attributes[DeviceAttributes.life2] is None
        assert self.device.attributes[DeviceAttributes.life3] is None
        assert not self.device.attributes[DeviceAttributes.child_lock]

    def test_process_message(self) -> None:
        """Test process message."""
        with patch("midealocal.devices.ed.MessageEDResponse") as mock_message_response:
            mock_message = mock_message_response.return_value
            mock_message.protocol_version = ProtocolVersion.V3
            mock_message.power = True
            mock_message.water_consumption = 123
            mock_message.in_tds = 200
            mock_message.out_tds = 5
            mock_message.filter1 = 30
            mock_message.filter2 = 20
            mock_message.filter3 = 10
            mock_message.life1 = 2
            mock_message.life2 = 3
            mock_message.life3 = 4
            mock_message.child_lock = True
            new_status = self.device.process_message(b"")
            assert new_status[DeviceAttributes.power.value]
            assert new_status[DeviceAttributes.water_consumption.value] == 123
            assert new_status[DeviceAttributes.in_tds.value] == 200
            assert new_status[DeviceAttributes.out_tds.value] == 5
            assert new_status[DeviceAttributes.filter1.value] == 30
            assert new_status[DeviceAttributes.filter2.value] == 20
            assert new_status[DeviceAttributes.filter3.value] == 10
            assert new_status[DeviceAttributes.life1.value] == 2
            assert new_status[DeviceAttributes.life2.value] == 3
            assert new_status[DeviceAttributes.life3.value] == 4

            mock_message.child_lock = False
            mock_message.water_consumption = 456
            mock_message.in_tds = 300
            mock_message.out_tds = 15
            mock_message.filter1 = 15
            mock_message.life3 = 15
            new_status = self.device.process_message(b"")
            assert not new_status[DeviceAttributes.child_lock.value]
            assert new_status[DeviceAttributes.water_consumption.value] == 456
            assert new_status[DeviceAttributes.in_tds.value] == 300
            assert new_status[DeviceAttributes.out_tds.value] == 15
            assert new_status[DeviceAttributes.filter1.value] == 15
            assert new_status[DeviceAttributes.life3.value] == 15

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 3
        assert isinstance(queries[0], MessageQuery)
        assert isinstance(queries[1], MessageQuery01)
        assert isinstance(queries[2], MessageQueryFF)

    @pytest.mark.parametrize(
        ("subtype", "expected_query"),
        [
            (309, MessageQuery04),
            (316, MessageQuery05),
            (290, MessageQuery06),
            (288, MessageQuery07),
            (775, MessageQuery01),
        ],
    )
    def test_build_query_subtypes(
        self,
        subtype: int,
        expected_query: type[MessageEDBase],
    ) -> None:
        """Test build query for subtype specific queries."""
        device = MideaEDDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.100",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="test_model",
            subtype=subtype,
            customize="test_customize",
        )
        queries = device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], expected_query)

    def test_set_attribute(self) -> None:
        """Test set attribute."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_build_send.assert_called_once()

            self.device.set_attribute(DeviceAttributes.child_lock, True)
            mock_build_send.assert_called()


class TestMideaEDDeviceSoftWater:
    """Test Midea ED Device soft water machine (subtype 703)."""

    device: MideaEDDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea soft water device setup (subtype 703)."""
        self.device = MideaEDDevice(
            name="Soft Water",
            device_id=2,
            ip_address="192.168.1.101",
            port=6444,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V3,
            model="6360000A",
            subtype=703,
            customize="",
        )

    def test_initial_soft_water_attributes(self) -> None:
        """Test initial soft water machine attributes."""
        attrs = self.device.attributes
        assert attrs[DeviceAttributes.velocity] is None
        assert attrs[DeviceAttributes.soft_available] is None
        assert attrs[DeviceAttributes.left_salt] is None
        assert attrs[DeviceAttributes.leak_water_protection_value] is None
        assert attrs[DeviceAttributes.remaining_days] is None
        assert attrs[DeviceAttributes.water_hardness] is None
        assert attrs[DeviceAttributes.flushing_days] is None
        assert attrs[DeviceAttributes.timing_regeneration_hour] is None
        assert attrs[DeviceAttributes.timing_regeneration_min] is None
        assert attrs[DeviceAttributes.regeneration_left_seconds] is None
        assert attrs[DeviceAttributes.use_days] is None
        assert attrs[DeviceAttributes.salt_setting] is None
        assert attrs[DeviceAttributes.soften] is False
        assert attrs[DeviceAttributes.cl_sterilization] is False
        assert attrs[DeviceAttributes.leak_water_protection] is False
        assert attrs[DeviceAttributes.water_way] is False
        assert attrs[DeviceAttributes.regeneration] is False
        assert attrs[DeviceAttributes.error] is None

    def test_build_query_uses_message_query09(self) -> None:
        """Test subtype 703 uses MessageQuery09."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery09)

    def test_set_attribute_soften(self) -> None:
        """Test setting soften switch."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.soften, True)
            mock_build_send.assert_called_once()

    def test_set_attribute_water_hardness(self) -> None:
        """Test setting water_hardness number."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.water_hardness, 150)
            mock_build_send.assert_called_once()

    def test_set_attribute_timing_regeneration_hour_couples_min(self) -> None:
        """Test setting hour also sends current min value (coupled write)."""
        # Set current min value in attributes
        self.device._attributes[DeviceAttributes.timing_regeneration_min] = 30
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.timing_regeneration_hour, 2)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.timing_regeneration_hour == 2
            assert sent_message.timing_regeneration_min == 30

    def test_set_attribute_timing_regeneration_min_couples_hour(self) -> None:
        """Test setting min also sends current hour value (coupled write)."""
        self.device._attributes[DeviceAttributes.timing_regeneration_hour] = 5
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.timing_regeneration_min, 45)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.timing_regeneration_min == 45
            assert sent_message.timing_regeneration_hour == 5

    def test_set_attribute_leak_water_protection_value_couples_switch(self) -> None:
        """Test setting leak_water_protection_value also sends current switch state."""
        self.device._attributes[DeviceAttributes.leak_water_protection] = True
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.leak_water_protection_value, 400)
            mock_build_send.assert_called_once()
            sent_message = mock_build_send.call_args[0][0]
            assert sent_message.leak_water_protection_value == 400
            assert sent_message.leak_water_protection is True

    def test_set_attribute_old_set(self) -> None:
        """Test set attribute with the old set message."""
        with (
            patch.object(self.device, "_use_new_set", return_value=False),
            patch.object(self.device, "build_send") as mock_build_send,
        ):
            self.device.set_attribute(DeviceAttributes.power, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageOldSet)
            # power is set dynamically via setattr in set_attribute
            assert getattr(message, "power", None) is True
