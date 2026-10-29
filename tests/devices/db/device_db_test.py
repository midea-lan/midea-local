"""Test DB Device."""

from unittest.mock import patch

import pytest

from midealocal.const import ProtocolVersion
from midealocal.devices.db import (
    DBModelProfile,
    DBParameterSpec,
    DeviceAttributes,
    MideaDBDevice,
)
from midealocal.devices.db.message import (
    MessagePower,
    MessageQuery,
    MessageSet,
    MessageStart,
)
from midealocal.exceptions import ValueWrongType
from midealocal.message import MessageType


class TestMideaDBDevice:
    """Test Midea DB Device."""

    device: MideaDBDevice

    @pytest.fixture(autouse=True)
    def _setup_device(self) -> None:
        """Midea DB Device setup."""
        self.device = self._make_device()

    @staticmethod
    def _make_device(model: str = "test_model", subtype: int = 1) -> MideaDBDevice:
        """Construct a device with its variant known at initialization."""
        return MideaDBDevice(
            name="Test Device",
            device_id=1,
            ip_address="192.168.1.1",
            port=12345,
            token="AA",
            key="BB",
            device_protocol=ProtocolVersion.V1,
            model=model,
            subtype=subtype,
            customize="",
        )

    def test_initial_attributes(self) -> None:
        """Test initial attributes."""
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.start] is False
        assert self.device.attributes[DeviceAttributes.status] == "idle"
        assert self.device.attributes[DeviceAttributes.mode] == "normal"
        assert self.device.attributes[DeviceAttributes.program] == "default"
        assert self.device.attributes[DeviceAttributes.water_level] == "default"
        assert self.device.attributes[DeviceAttributes.temperature] == "default"
        assert self.device.attributes[DeviceAttributes.dehydration_speed] == "default"
        assert self.device.attributes[DeviceAttributes.wash_time] is None
        assert self.device.attributes[DeviceAttributes.dehydration_time] is None
        assert self.device.attributes[DeviceAttributes.detergent] is None
        assert self.device.attributes[DeviceAttributes.softener] is None
        assert self.device.attributes[DeviceAttributes.progress] == "unknown"
        assert self.device.attributes[DeviceAttributes.stains] is None
        assert self.device.attributes[DeviceAttributes.time_remaining] is None
        assert self.device.attributes[DeviceAttributes.wash_time_value] is None
        assert self.device.attributes[DeviceAttributes.dehydration_time_value] is None
        assert self.device.attributes[DeviceAttributes.dirty_degree] is None

    def test_build_query(self) -> None:
        """Test build query."""
        queries = self.device.build_query()
        assert len(queries) == 1
        assert isinstance(queries[0], MessageQuery)

    def test_mode_options(self) -> None:
        """mode_options lists the DB modes in enum order."""
        assert MideaDBDevice.mode_options() == [
            "normal",
            "factory_test",
            "service",
            "normal_continus",
        ]

    @pytest.mark.parametrize(
        ("attributes", "expected_washing_data"),
        [
            ({}, bytearray([0x00] + [0xFF] * 12)),
            ({DeviceAttributes.mode: None}, bytearray([0xFF] * 13)),
            (
                {
                    DeviceAttributes.mode: "factory_test",
                    DeviceAttributes.program: "quick_wash",
                    DeviceAttributes.water_level: "high",
                    DeviceAttributes.temperature: "40",
                    DeviceAttributes.dehydration_speed: "1200",
                    DeviceAttributes.wash_time: 30,
                    DeviceAttributes.dehydration_time: 10,
                    DeviceAttributes.detergent: 1,
                    DeviceAttributes.softener: 2,
                },
                bytearray(
                    [
                        0x01,
                        0x12,
                        0x03,
                        0xFF,
                        0x04,
                        0x05,
                        0x1E,
                        0x0A,
                        0x01,
                        0x02,
                        0xFF,
                        0xFF,
                        0xFF,
                    ],
                ),
            ),
            (
                {
                    DeviceAttributes.mode: "factory_test",
                    DeviceAttributes.program: "specialist",
                    DeviceAttributes.water_level: "auto",
                    DeviceAttributes.temperature: "95",
                    DeviceAttributes.dehydration_speed: "1000",
                    DeviceAttributes.wash_time: 90,
                    DeviceAttributes.dehydration_time: 20,
                    DeviceAttributes.detergent: 4,
                    DeviceAttributes.softener: 3,
                },
                bytearray(
                    [
                        0x01,
                        0x23,
                        0x05,
                        0xFF,
                        0x06,
                        0x04,
                        90,
                        20,
                        4,
                        3,
                        0xFF,
                        0xFF,
                        0xFF,
                    ],
                ),
            ),
        ],
    )
    def test_build_washing_data_mode(
        self,
        attributes: dict[str, str | int | None],
        expected_washing_data: bytearray,
    ) -> None:
        """Build washing data from the mode name, defaulting unmapped modes."""
        for attr, value in attributes.items():
            self.device._attributes[attr] = value

        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.start.value, True)

            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageStart)
            assert message.body[1:] == bytearray([0xFF, 0x01]) + expected_washing_data

            mock_build_send.reset_mock()

            self.device.set_attribute(DeviceAttributes.start.value, False)

            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageStart)
            assert message.body[1:] == bytearray([0xFF, 0x00])

    @pytest.mark.parametrize(
        "message_type",
        [MessageType.query, MessageType.set],
    )
    def test_query_set_response(self, message_type: MessageType) -> None:
        """Test query/set response with mapped values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [message_type],
        )
        body = bytearray(31)
        body[0] = 0x03  # Body type
        body[1] = 0x01  # power
        body[2] = 0x02  # status start
        body[3] = 0x00  # mode normal
        body[4] = 0x02  # program fast_wash
        body[5] = 0x03  # water level High
        body[7] = 0x04  # temperature 40
        body[8] = 0x05  # dehydration speed 1200
        body[9] = 0x28  # wash time
        body[10] = 0x0A  # dehydration time
        body[11] = 0x01  # detergent
        body[12] = 0x02  # softener
        body[16] = 0x01  # progress Spin
        body[17] = 30  # time remaining low byte
        body[18] = 1  # time remaining high byte
        body[26] = 0x03  # stains
        body[27] = 0x28  # wash time value
        body[28] = 0x0A  # dehydration time value
        body[30] = 0x04  # dirty degree
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is True
        assert self.device.attributes[DeviceAttributes.start] is True
        assert self.device.attributes[DeviceAttributes.status] == "start"
        assert self.device.attributes[DeviceAttributes.mode] == "normal"
        assert self.device.attributes[DeviceAttributes.program] == "fast_wash"
        assert self.device.attributes[DeviceAttributes.water_level] == "high"
        assert self.device.attributes[DeviceAttributes.temperature] == "40"
        assert self.device.attributes[DeviceAttributes.dehydration_speed] == "1200"
        assert self.device.attributes[DeviceAttributes.wash_time] == 0x28
        assert self.device.attributes[DeviceAttributes.dehydration_time] == 0x0A
        assert self.device.attributes[DeviceAttributes.detergent] == 1
        assert self.device.attributes[DeviceAttributes.softener] == 2
        assert self.device.attributes[DeviceAttributes.progress] == "spin"
        assert self.device.attributes[DeviceAttributes.stains] == 3
        assert self.device.attributes[DeviceAttributes.time_remaining] == 286
        assert self.device.attributes[DeviceAttributes.wash_time_value] == 0x28
        assert self.device.attributes[DeviceAttributes.dehydration_time_value] == 0x0A
        assert self.device.attributes[DeviceAttributes.dirty_degree] == 4

    def test_notify1_response_unmapped_values(self) -> None:
        """Test notify1 response with unmapped values."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(31)
        body[0] = 0x04  # Body type
        body[2] = 9  # unmapped status
        body[3] = 5  # unmapped mode
        body[4] = 0x41  # unmapped program
        body[5] = 0x06  # unmapped water level
        body[7] = 0x10  # unmapped temperature
        body[8] = 0x09  # unmapped dehydration speed
        crc = bytearray([0x00])
        self.device.process_message(bytes(header + body + crc))
        assert self.device.attributes[DeviceAttributes.power] is False
        assert self.device.attributes[DeviceAttributes.start] is False
        assert self.device.attributes[DeviceAttributes.status] == 9
        assert self.device.attributes[DeviceAttributes.mode] == 5
        assert self.device.attributes[DeviceAttributes.program] == 0x41
        assert self.device.attributes[DeviceAttributes.water_level] == 6
        assert self.device.attributes[DeviceAttributes.temperature] == 0x10
        assert self.device.attributes[DeviceAttributes.dehydration_speed] == 9
        assert self.device.attributes[DeviceAttributes.progress] == "idle"
        assert self.device.attributes[DeviceAttributes.time_remaining] is None

    def test_unexpected_response(self) -> None:
        """Test notify1 response with unexpected body type updates no attribute."""
        header = bytearray(
            [0xAA] + ([0x0] * 7) + [ProtocolVersion.V1] + [MessageType.notify1],
        )
        body = bytearray(31)
        body[0] = 0x03  # unexpected body type for notify1
        crc = bytearray([0x00])
        new_status = self.device.process_message(bytes(header + body + crc))
        assert new_status == {}

    def test_set_attribute_power(self) -> None:
        """Test set attribute power sends a power message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.power.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessagePower)
            assert message.power is True

    def test_set_attribute_start(self) -> None:
        """Test set attribute start sends a start message."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.start.value, True)
            mock_build_send.assert_called_once()
            message = mock_build_send.call_args[0][0]
            assert isinstance(message, MessageStart)
            assert message.start is True
            assert message.washing_data == self.device._build_washing_data()

    def test_set_attribute_not_supported(self) -> None:
        """Test set attribute with an unsupported attribute does not send."""
        with patch.object(self.device, "build_send") as mock_build_send:
            self.device.set_attribute(DeviceAttributes.detergent.value, True)
            mock_build_send.assert_not_called()

    @pytest.mark.parametrize(
        ("attr", "value", "offset", "encoded"),
        [
            (DeviceAttributes.program, "mixed_wash", 4, 0x03),
            (DeviceAttributes.program, "underwear", 4, 0x0D),
            (DeviceAttributes.program, "outdoor", 4, 0x0E),
            (DeviceAttributes.program, "air_wash", 4, 0x15),
            (DeviceAttributes.program, "single_drying", 4, 0x16),
            (DeviceAttributes.program, "diy0", 4, 0x50),
            (DeviceAttributes.program, "diy1", 4, 0x51),
            (DeviceAttributes.temperature, "0", 7, 0x01),
            (DeviceAttributes.temperature, "40", 7, 0x04),
            (DeviceAttributes.temperature, "95", 7, 0x06),
            (DeviceAttributes.water_level, "low", 5, 0x01),
            (DeviceAttributes.water_level, "mid", 5, 0x02),
            (DeviceAttributes.water_level, "high", 5, 0x03),
            (DeviceAttributes.water_level, "4", 5, 0x04),
            (DeviceAttributes.water_level, "auto", 5, 0x05),
            (DeviceAttributes.dehydration_speed, "0", 8, 0x00),
            (DeviceAttributes.dehydration_speed, "400", 8, 0x01),
            (DeviceAttributes.dehydration_speed, "600", 8, 0x02),
            (DeviceAttributes.dehydration_speed, "800", 8, 0x03),
            (DeviceAttributes.dehydration_speed, "1000", 8, 0x04),
            (DeviceAttributes.dehydration_speed, "1200", 8, 0x05),
            (DeviceAttributes.dehydration_speed, "1400", 8, 0x06),
            (DeviceAttributes.dehydration_speed, "1600", 8, 0x07),
            (DeviceAttributes.dehydration_speed, "1300", 8, 0x08),
            (DeviceAttributes.wash_time, 0, 9, 0),
            (DeviceAttributes.wash_time, 2, 9, 2),
            (DeviceAttributes.wash_time, 4, 9, 4),
            (DeviceAttributes.dehydration_time, 0, 10, 0),
            (DeviceAttributes.dehydration_time, 2, 10, 2),
            (DeviceAttributes.dehydration_time, 4, 10, 4),
            (DeviceAttributes.detergent, 0, 11, 0),
            (DeviceAttributes.detergent, 4, 11, 4),
            (DeviceAttributes.detergent, 5, 11, 5),
        ],
    )
    @pytest.mark.parametrize("subtype", [0, 13146])
    def test_set_parameter(
        self,
        attr: DeviceAttributes,
        value: str | int,
        offset: int,
        encoded: int,
        subtype: int,
    ) -> None:
        """Parameter writes preserve all other fields, including work status."""
        self.device = self._make_device("38131408", subtype)
        before = self.device.attributes.copy()
        with patch.object(self.device, "build_send") as send:
            self.device.set_attribute(attr, value)
        send.assert_called_once()
        message = send.call_args.args[0]
        assert isinstance(message, MessageSet)
        expected = bytearray([0x02] + [0xFF] * 21)
        expected[offset] = encoded
        assert message.body == expected
        assert self.device.attributes == before

    @pytest.mark.parametrize(
        "attr",
        [
            DeviceAttributes.program,
            DeviceAttributes.temperature,
            DeviceAttributes.water_level,
            DeviceAttributes.dehydration_speed,
        ],
    )
    @pytest.mark.parametrize("value", [True, False, 40, 40.5, "invalid", "default", ""])
    def test_set_parameter_invalid(
        self, attr: DeviceAttributes, value: bool | float | str
    ) -> None:
        """Invalid values must not send a control message."""
        self.device = self._make_device("38131408", 13146)
        with (
            patch.object(self.device, "build_send") as send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize(
        ("code", "legacy_name", "legacy_start_code", "target_name"),
        [
            (0x0D, "outdoor", 0x0D, "underwear"),
            (0x0E, "air_wash", 0x0E, "outdoor"),
            (0x15, "single_drying", 0x15, "air_wash"),
            (0x16, "single_drying", 0x15, "single_drying"),
            (0x50, "water_fiber", 0x20, "diy0"),
            (0x51, "diy0", 0x51, "diy1"),
        ],
    )
    @pytest.mark.parametrize("model", ["38131408", "test_model", ""])
    @pytest.mark.parametrize("subtype", [0, 13146, 1])
    def test_program_mapping_is_model_specific(
        self,
        code: int,
        legacy_name: str,
        legacy_start_code: int,
        target_name: str,
        model: str,
        subtype: int,
    ) -> None:
        """Only the target model changes decoded names and start encoding."""
        self.device = self._make_device(model, subtype)
        header = bytearray([0xAA] + [0] * 7 + [ProtocolVersion.V1, MessageType.query])
        body = bytearray(31)
        body[0] = 0x03
        body[4] = code
        self.device.process_message(bytes(header + body + bytearray([0])))
        target = model == "38131408" and subtype in (0, 13146)
        assert self.device.attributes[DeviceAttributes.program] == (
            target_name if target else legacy_name
        )
        with patch.object(self.device, "build_send") as send:
            self.device.set_attribute(DeviceAttributes.start, True)
        message = send.call_args.args[0]
        assert isinstance(message, MessageStart)
        expected_data = bytearray(
            [0x00, code if target else legacy_start_code, 0xFF, 0xFF, 0x01]
            + [0x00] * 5
            + [0xFF] * 3,
        )
        assert message.body == bytearray([0x02, 0xFF, 0x01]) + expected_data

    @pytest.mark.parametrize("model", ["test_model", "", "38131409"])
    @pytest.mark.parametrize("subtype", [0, 13146])
    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.program, "mixed_wash"),
            (DeviceAttributes.temperature, "40"),
        ],
    )
    def test_other_models_reject_parameter_writes(
        self,
        model: str,
        subtype: int,
        attr: DeviceAttributes,
        value: str,
    ) -> None:
        """Neither a subtype match nor an unknown model enables new writes."""
        self.device = self._make_device(model, subtype)
        with (
            patch.object(self.device, "build_send") as send,
            pytest.raises(ValueWrongType, match="Expected bool"),
        ):
            self.device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize(
        "attr",
        [
            DeviceAttributes.program,
            DeviceAttributes.temperature,
            DeviceAttributes.water_level,
            DeviceAttributes.dehydration_speed,
            DeviceAttributes.wash_time,
            DeviceAttributes.dehydration_time,
            DeviceAttributes.detergent,
            DeviceAttributes.softener,
        ],
    )
    @pytest.mark.parametrize("value", [True, False])
    def test_other_models_keep_unsupported_boolean_noop(
        self,
        attr: DeviceAttributes,
        value: bool,
    ) -> None:
        """Preserve the previous unsupported-attribute behavior exactly."""
        with patch.object(self.device, "build_send") as send:
            self.device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize("subtype", [1, 999])
    @pytest.mark.parametrize(
        ("attr", "value"),
        [(DeviceAttributes.program, "cotton"), (DeviceAttributes.temperature, "40")],
    )
    def test_same_model_unknown_subtype_uses_default(
        self,
        subtype: int,
        attr: DeviceAttributes,
        value: str,
    ) -> None:
        """Known but unregistered subtypes cannot acquire parameter writes."""
        device = self._make_device("38131408", subtype)
        assert device._model_profile is MideaDBDevice._default_profile
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType, match="Expected bool"),
        ):
            device.set_attribute(attr, value)
        send.assert_not_called()

    def test_cli_and_verified_subtype_share_profile(self) -> None:
        """The CLI exception is explicit and shares the verified configuration."""
        cli_device = self._make_device("38131408", 0)
        verified_device = self._make_device("38131408", 13146)
        assert cli_device._model_profile is verified_device._model_profile
        assert cli_device._model_profile.writable_attributes == frozenset(
            {
                DeviceAttributes.program,
                DeviceAttributes.temperature,
                DeviceAttributes.water_level,
                DeviceAttributes.dehydration_speed,
                DeviceAttributes.wash_time,
                DeviceAttributes.dehydration_time,
                DeviceAttributes.detergent,
                DeviceAttributes.dryer,
                DeviceAttributes.steam_wash,
                DeviceAttributes.fast_clean_wash,
            },
        )

    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.status, "standby"),
            (DeviceAttributes.mode, "factory_test"),
            (DeviceAttributes.progress, "wash"),
            (DeviceAttributes.time_remaining, 30),
            (DeviceAttributes.wash_time_value, 30),
            (DeviceAttributes.dehydration_time_value, 8),
            (DeviceAttributes.stains, 1),
            (DeviceAttributes.dirty_degree, 1),
        ],
    )
    def test_unverified_or_read_only_parameters_are_not_writable(
        self,
        attr: DeviceAttributes,
        value: str | int,
    ) -> None:
        """Only explicitly registered fields can generate parameter writes."""
        device = self._make_device("38131408", 13146)
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType),
        ):
            device.set_attribute(attr, value)
        send.assert_not_called()

    def test_profile_programs_are_read_only(self) -> None:
        """Consumers cannot mutate a shared profile's program mapping."""
        device = self._make_device("38131408", 13146)
        with pytest.raises(TypeError):
            device._model_profile.programs[0x03] = "other"  # type: ignore[index]

    def test_registered_profile_drives_parameter_writes(self) -> None:
        """Registering another variant needs no model checks in control code."""
        profile = DBModelProfile(
            programs={0x12: "test_program"},
            parameters={
                DeviceAttributes.program: DBParameterSpec(3, {0x12: "test_program"})
            },
        )
        with patch.dict(MideaDBDevice._model_profiles, {("test_model", 2): profile}):
            device = self._make_device("test_model", 2)
        assert device._model_profile is profile
        with patch.object(device, "build_send") as send:
            device.set_attribute(DeviceAttributes.program, "test_program")
        message = send.call_args.args[0]
        assert isinstance(message, MessageSet)
        assert message.body == bytearray([0x02, 0xFF, 0xFF, 0xFF, 0x12] + [0xFF] * 17)
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType, match="Expected bool"),
        ):
            device.set_attribute(DeviceAttributes.temperature, "40")
        send.assert_not_called()

    @pytest.mark.parametrize(
        "attr", [DeviceAttributes.wash_time, DeviceAttributes.dehydration_time]
    )
    @pytest.mark.parametrize("value", [True, False, -1, 255, 256, 1.5, "25", "default"])
    def test_time_parameter_invalid(
        self, attr: DeviceAttributes, value: bool | float | str
    ) -> None:
        """Raw time writes require integers and exclude the unchanged sentinel."""
        device = self._make_device("38131408", 13146)
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType),
        ):
            device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize("attr", [DeviceAttributes.detergent])
    @pytest.mark.parametrize("value", [True, False, -1, 6, 9, 255, 1.5, "4"])
    def test_dosage_parameter_invalid(
        self, attr: DeviceAttributes, value: bool | float | str
    ) -> None:
        """Dosage writes use numeric levels 0-5, not wider reported statuses."""
        device = self._make_device("38131408", 13146)
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType),
        ):
            device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize(
        ("model", "subtype"), [("38131408", 1), ("test_model", 13146)]
    )
    @pytest.mark.parametrize(
        ("attr", "value"),
        [
            (DeviceAttributes.water_level, "auto"),
            (DeviceAttributes.dehydration_speed, "1200"),
            (DeviceAttributes.wash_time, 25),
            (DeviceAttributes.dehydration_time, 8),
            (DeviceAttributes.detergent, 4),
            (DeviceAttributes.softener, 0),
        ],
    )
    def test_additional_parameters_remain_model_specific(
        self,
        model: str,
        subtype: int,
        attr: DeviceAttributes,
        value: str | int,
    ) -> None:
        """Unregistered variants preserve their previous control behavior."""
        device = self._make_device(model, subtype)
        with (
            patch.object(device, "build_send") as send,
            pytest.raises(ValueWrongType, match="Expected bool"),
        ):
            device.set_attribute(attr, value)
        send.assert_not_called()

    @pytest.mark.parametrize("subtype", [0, 13146])
    @pytest.mark.parametrize("value", [0, 2, 5, "2", True, False])
    def test_target_model_has_no_softener_parameter(
        self,
        subtype: int,
        value: int | str | bool,
    ) -> None:
        """A Lua field alone does not establish this model's hardware capability."""
        device = self._make_device("38131408", subtype)
        assert DeviceAttributes.softener not in device._model_profile.parameters
        with patch.object(device, "build_send") as send:
            if isinstance(value, bool):
                device.set_attribute(DeviceAttributes.softener, value)
            else:
                with pytest.raises(ValueWrongType):
                    device.set_attribute(DeviceAttributes.softener, value)
        send.assert_not_called()

    def test_set_attribute_wrong_type(self) -> None:
        """Test set attribute with a non-bool value raises and does not send."""
        with (
            patch.object(self.device, "build_send") as mock_build_send,
            pytest.raises(ValueWrongType),
        ):
            self.device.set_attribute(DeviceAttributes.power.value, 5)
        mock_build_send.assert_not_called()
