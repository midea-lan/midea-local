"""
This is a Python conversion of the Lua code for the Midea washing machine protocol.
It handles the conversion between JSON and binary data formats for communication with the device.
"""

import json
import struct
from typing import Dict, List, Optional, Union, Any

# Constants
BYTE_PROTOCOL_LENGTH = 0x10

class LuaConverter:
    def __init__(self):
        pass

    dataType = 0x00
    subDataType = 0x00
    version = 30

    # Key mapping dictionary
    keyTable = {
        "KEY_VERSION": "version",
        "KEY_FUNCTION_TYPE": "function_type",
        "KEY_COMMAND": "command",
        "KEY_MODE": "mode",
        "KEY_PROGRAM": "program",
        "KEY_RESERVATION_HOUR": "reservation_hour",
        "KEY_RESERVATION_MIN": "reservation_min",
        "KEY_TIME_HOUR": "time_hour",
        "KEY_TIME_MIN": "time_min",
        "KEY_TIME_SEC": "time_sec",
        "KEY_WASH_TIME": "wash_time",
        "KEY_RINSE_POUR": "rinse_pour",
        "KEY_DEHYDRATION_TIME": "dehydration_time",
        "KEY_DRY": "dry",
        "KEY_WASH_RISE": "wash_rinse",
        "KEY_UFB": "ufb",
        "KEY_TEMPERATURE": "temperature",
        "KEY_LOCK": "lock",
        "KEY_TUB_AUTO_CLEAN": "tub_auto_clean",
        "KEY_BUZZER": "buzzer",
        "KEY_RINSE_MODE": "rinse_mode",
        "KEY_LOW_NOISE": "low_noise",
        "KEY_ENERGY_SAVING": "energy_saving",
        "KEY_HOT_WATER_FIFTEEN": "hot_water_fifteen",
        "KEY_DRY_FINISH_ADJUST": "dry_finish_adjust",
        "KEY_SPIN_ROTATE_ADJUST": "spin_rotate_adjust",
        "KEY_FUNGUS_PROTECT": "fungus_protect",
        "KEY_DRAIN_BUBBLE_PROTECT": "drain_bubble_protect",
        "KEY_DEFAULT_DRY": "default_dry",
        "KEY_PROCESS_INFO_WASH": "process_info_wash",
        "KEY_PROCESS_INFO_RINSE": "process_info_rinse",
        "KEY_PROCESS_INFO_SPIN": "process_info_spin",
        "KEY_PROCESS_INFO_DRY": "process_info_dry",
        "KEY_PROCESS_INFO_SOFT_KEEP": "process_info_soft_keep",
        "KEY_PROCESS_DETAIL": "process_detail",
        "KEY_ERROR": "error",
        "KEY_MACHINE_STATUS": "machine_status",
        "KEY_REMAIN_TIME": "remain_time",
        "KEY_DOOR_OPEN": "door_open",
        "KEY_REMAIN_TIME_ADJUST": "remain_time_adjust",
        "KEY_DRAIN_FILTER_CLEAN": "drain_filter_clean",
        "KEY_TUB_HIGH_HOT": "tub_high_hot",
        "KEY_WATER_HIGH_TEMPERATURE": "water_high_temperature",
        "KEY_TUB_WATER_EXIST": "tub_water_exist",
        "KEY_OVER_CAPACITY": "over_capacity",
        "KEY_DRAIN_FILTER_CARE": "drain_filter_care",
        "KEY_DRY_FILTER_CLEAN": "dry_filter_clean",
        "KEY_APP_COURSE_NUMBER": "app_course_number",
        "KEY_RESERVATION_MODE": "reservation_mode",
        "KEY_OPERATION_WASH_TIME": "operation_wash_time",
        "KEY_OPERATION_WASH_RINSE_TIMES": "operation_wash_rinse_times",
        "KEY_OPERATION_WASH_SPIN_TIME": "operation_wash_spin_time",
        "KEY_OPERATION_WASH_DRYER_TIME": "operation_wash_dryer_time",
        "KEY_OPERATION_WASH_DRYER_RINSE_TIMES": "operation_wash_dryer_rinse_times",
        "KEY_OPERATION_WASH_DRYER_SPIN_TIME": "operation_wash_dryer_spin_time",
        "KEY_OPERATION_WASH_DRYER_DRY_SET": "operation_wash_dryer_dry_set",
        "KEY_OPERATION_DRYER_DRY_SET": "operation_dryer_dry_set",
        "KEY_DETERGENT_REMAIN": "detergent_remain",
        "KEY_DETERGENT_REMAIN_EXPLANATION": "detergent_remain_explanation",
        "KEY_DETERGENT_SETTING": "detergent_setting",
        "KEY_SOFTNER_REMAIN": "softner_remain",
        "KEY_SOFTNER_REMAIN_EXPLANATION": "softner_remain_explanation",
        "KEY_SOFTNER_SETTING": "softner_setting",
        "KEY_DETERGENT_NAME": "detergent_name",
        "KEY_SOFTNER_NAME": "softner_name",
        "KEY_DETERGENT_MEASURE": "detergent_measure",
        "KEY_SOFTNER_MEASURE": "softner_measure",
        "KEY_BEGIN_PROCESS_WASH": "begin_process_wash",
        "KEY_BEGIN_PROCESS_RINSE": "begin_process_rinse",
        "KEY_BEGIN_PROCESS_SPIN": "begin_process_spin",
        "KEY_BEGIN_PROCESS_DRY": "begin_process_dry",
        "KEY_BEGIN_PROCESS_SOFT_KEEP": "begin_process_soft_keep",
        "KEY_RESERVATION_TIME_EARLIEST_HOUR": "reservation_time_earliest_hour",
        "KEY_RESERVATION_TIME_EARLIEST_MIN": "reservation_time_earliest_min",
        "KEY_RESERVATION_TIME_LATEST_HOUR": "reservation_time_latest_hour",
        "KEY_RESERVATION_TIME_LATEST_MIN": "reservation_time_latest_min"
    }

    # Protocol table with default values
    proTable = {
        "functionType": 0x00,
        "command": 0xff,
        "mode": 0xff,
        "program": 0xff,
        "reservationHour": 0xff,
        "reservationMin": 0xff,
        "timeHour": 0xff,
        "timeMin": 0xff,
        "timeSec": 0xff,
        "washTime": 0xff,
        "rinsePour": 0xff,
        "dehydrationTime": 0xff,
        "dry": 0xff,
        "washRinse": 0xff,
        "ufb": 0x00,
        "temperature": 0xff,
        "lock": 0xff,
        "tubAutoClean": 0xff,
        "buzzer": 0xff,
        "rinseMode": 0xff,
        "lowNoise": 0xff,
        "energySaving": 0xff,
        "hotWaterFifteen": 0xff,
        "dryFinishAdjust": None,
        "spinRotateAdjust": None,
        "fungusProtect": None,
        "drainBubbleProtect": None,
        "defaultDry": 0xff,
        "processInfo": 0,
        "processDetail": None,
        "errorCode": None,
        "error": None,
        "machineStatus": None,
        "remainTime": None,
        "doorOpen": None,
        "remainTimeAdjust": None,
        "drainFilterClean": None,
        "tubHighHot": None,
        "waterHighTemperature": None,
        "tubWaterExist": None,
        "overCapacity": None,
        "drainFilterCare": None,
        "dryFilterClean": None,
        "appCourseNumber": None,
        "reservationMode": None,
        "operationWashTime": None,
        "operationWashRinseTimes": None,
        "operationWashSpinTime": None,
        "operationWashDryerTime": None,
        "operationWashDryerRinseTimes": None,
        "operationWashDryerSpinTime": None,
        "operationWashDryerDrySet": None,
        "operationDryerDrySet": None,
        "detergentRemain": None,
        "detergentRemainExplanation": None,
        "detergentSetting": None,
        "softnerRemain": None,
        "softnerRemainExplanation": None,
        "softnerSetting": None,
        "detergentName": None,
        "softnerName": None,
        "detergentMeasure": None,
        "softnerMeasure": None,
        "beginProcess": 0,
        "reservationTimeEarliestHour": None,
        "reservationTimeEarliestMin": None,
        "reservationTimeLatestHour": None,
        "reservationTimeLatestMin": None,
        "errorYear": None,
        "errorMonth": None,
        "errorDay": None,
        "errorHour": None,
        "errorMin": None,
        "firm": None,
        "machineName": None,
        "e2prom": None,
        "dryClothWeight": None,
        "wetClothWeight": None,
        "operationStartTimeHour": None,
        "operationStartTimeMin": None,
        "operationEndTimeHour": None,
        "operationEndTimeMin": None,
        "remainTimeHour": None,
        "remainTimeMin": None,
        "operationTimeHour": None,
        "operationTimeMin": None,
        "presenceDetergent": None,
        "courseConfirmNumber": 0,
        "response_status": 0xff,
        "last_app_course_number": 0xff,
        "wash_course_one_program": 0xff,
        "wash_course_one_wash_time": 0xff,
        "wash_course_one_rinse_pour": 0xff,
        "wash_course_one_dehydration_time": 0xff,
        "wash_course_one_dry": 0xff,
        "wash_course_one_temperature": 0xff,
        "wash_course_one_wash_rinse": 0xff,
        "wash_course_one_ufb": 0xff,
        "wash_course_one_base_program": 0xff,
        "wash_course_two_program": 0xff,
        "wash_course_two_wash_time": 0xff,
        "wash_course_two_rinse_pour": 0xff,
        "wash_course_two_dehydration_time": 0xff,
        "wash_course_two_dry": 0xff,
        "wash_course_two_temperature": 0xff,
        "wash_course_two_wash_rinse": 0xff,
        "wash_course_two_ufb": 0xff,
        "wash_course_two_base_program": 0xff,
        "wash_course_three_program": 0xff,
        "wash_course_three_wash_time": 0xff,
        "wash_course_three_rinse_pour": 0xff,
        "wash_course_three_dehydration_time": 0xff,
        "wash_course_three_dry": 0xff,
        "wash_course_three_temperature": 0xff,
        "wash_course_three_wash_rinse": 0xff,
        "wash_course_three_ufb": 0xff,
        "wash_course_three_base_program": 0xff,
        "wash_dry_course_one_program": 0xff,
        "wash_dry_course_one_wash_time": 0xff,
        "wash_dry_course_one_rinse_pour": 0xff,
        "wash_dry_course_one_dehydration_time": 0xff,
        "wash_dry_course_one_dry": 0xff,
        "wash_dry_course_one_temperature": 0xff,
        "wash_dry_course_one_wash_rinse": 0xff,
        "wash_dry_course_one_ufb": 0xff,
        "wash_dry_course_one_base_program": 0xff,
        "wash_dry_course_two_program": 0xff,
        "wash_dry_course_two_wash_time": 0xff,
        "wash_dry_course_two_rinse_pour": 0xff,
        "wash_dry_course_two_dehydration_time": 0xff,
        "wash_dry_course_two_dry": 0xff,
        "wash_dry_course_two_temperature": 0xff,
        "wash_dry_course_two_wash_rinse": 0xff,
        "wash_dry_course_two_ufb": 0xff,
        "wash_dry_course_two_base_program": 0xff,
        "wash_dry_course_three_program": 0xff,
        "wash_dry_course_three_wash_time": 0xff,
        "wash_dry_course_three_rinse_pour": 0xff,
        "wash_dry_course_three_dehydration_time": 0xff,
        "wash_dry_course_three_dry": 0xff,
        "wash_dry_course_three_temperature": 0xff,
        "wash_dry_course_three_wash_rinse": 0xff,
        "wash_dry_course_three_ufb": 0xff,
        "wash_dry_course_three_base_program": 0xff,
        "inventoryUsageType": 0xff,
        "inventoryUsageAmount": 0xff,
        "inventoryUsageAccumulatedAmount": 0xff
    }

    # CRC8 table for checksums
    crc8_854_table = [
        0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
        157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
        35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
        190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
        70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
        219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
        101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
        248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
        140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
        17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
        175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
        50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
        202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
        87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
        233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
        116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
    ]

    def crc16_ccitt(self, tmpbuf: List[int], start_pos: int, end_pos: int) -> int:
        """Calculate CRC16-CCITT checksum."""
        crc = 0
        for si in range(start_pos, end_pos + 1):
            crc ^= (tmpbuf[si] << 8)
            for _ in range(8):
                if (crc & 0x8000) == 0x8000:
                    crc = ((crc << 1) ^ 0x1021) & 0xFFFF
                else:
                    crc = (crc << 1) & 0xFFFF
        return crc

    def crc8_854(self, dataBuf: List[int], start_pos: int, end_pos: int) -> int:
        """Calculate CRC8 checksum using the lookup table."""
        crc = 0
        for si in range(start_pos, end_pos + 1):
            crc = self.crc8_854_table[(crc ^ dataBuf[si]) & 0xFF]
        return crc

    def extract_body_bytes_lua(self, byte_data):
        """Python implementation of Lua's extractBodyBytes function."""
        msg_length = len(byte_data)
        msg_bytes = {}
        body_bytes = {}
        for i in range(1, msg_length + 1):
            msg_bytes[i - 1] = byte_data[i]
        
        body_length = msg_length - BYTE_PROTOCOL_LENGTH - 2
        for i in range(0, body_length):
            body_bytes[i] = msg_bytes[i + BYTE_PROTOCOL_LENGTH]
        
        return body_bytes

    def assemble_uart_lua(self, body_bytes, msg_type):
        """Python implementation of Lua's assembleUart function."""
        body_length = len(body_bytes) + 1
        msg_length = (body_length + BYTE_PROTOCOL_LENGTH + 2)
        msg_bytes = {}
        
        for i in range(0, msg_length):
            msg_bytes[i] = 0
        
        msg_bytes[0] = 0x55
        msg_bytes[1] = 0xAA
        msg_bytes[2] = 0xCC
        msg_bytes[3] = 0x33
        
        msg_len = msg_length - 4
        msg_bytes[4] = msg_len & 0xff
        msg_bytes[5] = (msg_len >> 8) & 0xff
        msg_bytes[6] = 0x01
        msg_bytes[7] = 0xDB
        msg_bytes[14] = msg_type & 0xff
        msg_bytes[15] = (msg_type >> 8) & 0xff
        
        for i in range(0, body_length - 1):
            msg_bytes[i + BYTE_PROTOCOL_LENGTH] = body_bytes[i]
        
        crc16 = self.crc16_ccitt(msg_bytes, 0, msg_length - 3)
        msg_bytes[msg_length - 2] = crc16 & 0xff
        msg_bytes[msg_length - 1] = (crc16 >> 8) & 0xff
        
        return msg_bytes

    def make_sum(self, tmpbuf: List[int], start_pos: int, end_pos: int) -> int:
        """Calculate checksum by summing bytes."""
        res_val = 0
        for si in range(start_pos, end_pos + 1):
            res_val += tmpbuf[si]
        res_val = (~res_val + 1) & 0xFF
        return res_val

    def decode_json_to_table(self, cmd):
        """Python implementation of Lua's decodeJsonToTable function."""
        try:
            return json.loads(cmd)
        except json.JSONDecodeError:
            return {}
    
    def encode_table_to_json(self, lua_table):
        """Python implementation of Lua's encodeTableToJson function."""
        try:
            return json.dumps(lua_table)
        except (TypeError, ValueError):
            return "{}"

    def extract_body_bytes(self, byte_data: List[int]) -> Dict[int, int]:
        """Extract the body bytes from the message."""
        msg_length = len(byte_data)
        msg_bytes = {i: byte_data[i+1] for i in range(msg_length-1)}
        body_length = msg_length - BYTE_PROTOCOL_LENGTH - 2
        body_bytes = {i: msg_bytes[i + BYTE_PROTOCOL_LENGTH] for i in range(body_length)}
        return body_bytes

    def assemble_uart(self, body_bytes: List[int], msg_type: int) -> List[int]:
        """Assemble UART message with protocol headers and CRC."""
        body_length = len(body_bytes)
        msg_length = body_length + BYTE_PROTOCOL_LENGTH + 2
        msg_bytes = [0] * msg_length
        
        # Set protocol header
        msg_bytes[0] = 0x55
        msg_bytes[1] = 0xAA
        msg_bytes[2] = 0xCC
        msg_bytes[3] = 0x33
        
        # Set message length
        msg_len = msg_length - 4
        msg_bytes[4] = msg_len & 0xff
        msg_bytes[5] = (msg_len >> 8) & 0xff
        
        # Set device identifier
        msg_bytes[6] = 0x01
        msg_bytes[7] = 0xDB
        
        # Set message type
        msg_bytes[14] = msg_type & 0xff
        msg_bytes[15] = (msg_type >> 8) & 0xff
        
        # Copy body bytes
        for i in range(body_length):
            msg_bytes[i + BYTE_PROTOCOL_LENGTH] = body_bytes[i]
        
        # Calculate and set CRC
        crc16 = self.crc16_ccitt(msg_bytes, 0, msg_length - 3)
        msg_bytes[msg_length - 2] = crc16 & 0xff
        msg_bytes[msg_length - 1] = (crc16 >> 8) & 0xff
        
        return msg_bytes

    def string_to_int(self, data: Any) -> int:
        """Convert string to integer with error handling."""
        if data is None:
            return 0
        try:
            return int(data)
        except (ValueError, TypeError):
            return 0

    def int_to_string(self, data: Any) -> str:
        """Convert integer to string with error handling."""
        if data is None:
            return "0"
        try:
            return str(data)
        except (ValueError, TypeError):
            return "0"

    def string_to_table(self, hexstr: str) -> dict:
        """Convert hex string to table of byte values."""
        tb = {}
        j = 1
        for i in range(0, len(hexstr) - 1, 2):
            doublebytestr = hexstr[i:i+2]
            tb[j] = int(doublebytestr, 16)
            j += 1
        return tb

    def string_to_hexstring(self, string: str) -> str:
        """Convert string to hex string representation."""
        ret = ""
        for char in string:
            ret += f"{ord(char):02x}"
        return ret

    def table_to_string(self, cmd: list) -> str:
        """Convert table of byte values to string."""
        ret = ""
        for byte in cmd:
            ret += chr(byte)
        return ret

    def check_boundary(self, data: Any, min_val: int, max_val: int) -> int:
        """Check if value is within boundaries and adjust if needed."""
        if data is None:
            return min_val
        
        try:
            val = int(data)
            if min_val <= val <= max_val:
                return val
            return min_val if val < min_val else max_val
        except (ValueError, TypeError):
            return min_val

    def update_property_of_program(self, key: str, value: str) -> None:
        """Update program property based on string value."""
        if value == "none":
            self.proTable[key] = 0x00
        elif value == "standard":
            self.proTable[key] = 0x01
        elif value == "tub_clean":
            self.proTable[key] = 0x02
        elif value == "fast":
            self.proTable[key] = 0x03
        elif value == "careful":
            self.proTable[key] = 0x04
        elif value == "sixty_wash":
            self.proTable[key] = 0x05
        elif value == "blanket":
            self.proTable[key] = 0x06
        elif value == "delicate":
            self.proTable[key] = 0x07
        elif value == "tub_clean_dry":
            self.proTable[key] = 0x08
        elif value == "memory":
            self.proTable[key] = 0x09
        elif value == "sterilization":
            self.proTable[key] = 0x0A
        elif value == "mute":
            self.proTable[key] = 0x0B
        elif value == "soft":
            self.proTable[key] = 0x0C
        elif value == "delicate_dryer":
            self.proTable[key] = 0x0D
        elif value == "soak":
            self.proTable[key] = 0x0E
        elif value == "odor_eliminating":
            self.proTable[key] = 0x0F
        elif value == "empty":
            self.proTable[key] = 0x10
        elif value == "degerm":
            self.proTable[key] = 0x11
        elif value == "auto_care":
            self.proTable[key] = 0x12
        elif value == "auto_twice_wash":
            self.proTable[key] = 0x13
        elif value == "prewash_plus":
            self.proTable[key] = 0x14
        elif value == "uv_wash_and_dry":
            self.proTable[key] = 0x15
        elif value == "uv_dry_with_rotation":
            self.proTable[key] = 0x16
        elif value == "uv_dry_without_rotation":
            self.proTable[key] = 0x17
        elif value == "forty_five_wash":
            self.proTable[key] = 0x18
        elif value == "fragrant_and_delicate":
            self.proTable[key] = 0x1C
        elif value == "tick_extermination":
            self.proTable[key] = 0x1D
        elif value == "pollen":
            self.proTable[key] = 0x1E
        elif value == "app_course_1":
            self.proTable[key] = 0x21
        elif value == "app_course_2":
            self.proTable[key] = 0x22
        elif value == "app_course_3":
            self.proTable[key] = 0x23
        elif value == "app_course":
            self.proTable[key] = 0x24
        elif value == "uv_wash":
            self.proTable[key] = 0x25
        elif value == "uv_without_rotation":
            self.proTable[key] = 0x26
        elif value == "uv_with_rotation":
            self.proTable[key] = 0x27
        elif value == "uv_deodorize_without_rotation":
            self.proTable[key] = 0x28
        elif value == "uv_deodorize_with_rotation":
            self.proTable[key] = 0x29
        elif value == "60_tub_clean":
            self.proTable[key] = 0x30
        elif value == "sheets":
            self.proTable[key] = 0x51
        elif value == "lace_curtain":
            self.proTable[key] = 0x52
        elif value == "towel":
            self.proTable[key] = 0x53
        elif value == "fleece":
            self.proTable[key] = 0x54
        elif value == "school_uniform_or_washable":
            self.proTable[key] = 0x55
        elif value == "slacks_skirt":
            self.proTable[key] = 0x56
        elif value == "jeans":
            self.proTable[key] = 0x57
        elif value == "cap":
            self.proTable[key] = 0x58
        elif value == "down_jacket":
            self.proTable[key] = 0x59
        elif value == "bet_putt":
            self.proTable[key] = 0x5A
        elif value == "functional_underwear":
            self.proTable[key] = 0x5B
        elif value == "reusable_bag":
            self.proTable[key] = 0x5C
        elif value == "duvet":
            self.proTable[key] = 0x5D
        elif value == "t_shirt_recovery":
            self.proTable[key] = 0x5E
        elif value == "sports_wear":
            self.proTable[key] = 0x5F
        elif value == "light_dirt":
            self.proTable[key] = 0x81
        elif value == "wash_thoroughly_and_rinse":
            self.proTable[key] = 0x82
        elif value == "quick_wash_and_dry":
            self.proTable[key] = 0x83
        elif value == "yellowing_off":
            self.proTable[key] = 0x84
        elif value == "disinfection_clothing":
            self.proTable[key] = 0x85
        elif value == "keep_water_temperature":
            self.proTable[key] = 0x86
        elif value == "prewash":
            self.proTable[key] = 0x87
        elif value == "super_concentrated_soak":
            self.proTable[key] = 0x91
        elif value == "no_rinse_and_delicate":
            self.proTable[key] = 0x92
        elif value == "t_shirt_recovery_pro":
            self.proTable[key] = 0x93
        elif value == "customize":
            self.proTable[key] = 0xA0

    def update_property_of_wash_time(self, key: str, value: Any) -> None:
        """Update wash time property based on value."""
        if value is not None:
            tmp_time = self.string_to_int(value)
            if tmp_time == 1 * 60:
                self.proTable[key] = 0x81
            elif tmp_time == 2 * 60:
                self.proTable[key] = 0x82
            elif tmp_time == 3 * 60:
                self.proTable[key] = 0x83
            elif tmp_time == 4 * 60:
                self.proTable[key] = 0x84
            elif tmp_time == 5 * 60:
                self.proTable[key] = 0x85
            elif tmp_time == 6 * 60:
                self.proTable[key] = 0x86
            elif tmp_time == 7 * 60:
                self.proTable[key] = 0x87
            elif tmp_time == 8 * 60:
                self.proTable[key] = 0x88
            elif tmp_time == 9 * 60:
                self.proTable[key] = 0x89
            elif tmp_time == 10 * 60:
                self.proTable[key] = 0x8A
            elif tmp_time == 11 * 60:
                self.proTable[key] = 0x8B
            elif tmp_time == 12 * 60:
                self.proTable[key] = 0x8C
            else:
                self.proTable[key] = tmp_time

    def update_property_of_wash_rise(self, key: str, value: str) -> None:
        """Update wash rise property based on string value."""
        if value == "none":
            self.proTable[key] = 0x00
        elif value == "wash":
            self.proTable[key] = 0x01
        elif value == "wash_to_rinse":
            self.proTable[key] = 0x02
        elif value == "rinse":
            self.proTable[key] = 0x03

    def update_property_of_ubf(self, key: str, value: str) -> None:
        """Update UFB property based on string value."""
        if value == "on":
            self.proTable[key] = 0x80
        elif value == "off":
            self.proTable[key] = 0x00

    def update_global_property_value_by_json(self, lua_table: Dict[str, Any]) -> None:
        """Update global properties based on JSON data."""
        # Command
        if lua_table.get(self.keyTable["KEY_COMMAND"]) == "none":
            self.proTable["command"] = 0x00
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "temporary_stop":
            self.proTable["command"] = 0x01
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "reservation_fix":
            self.proTable["command"] = 0x02
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "reservation_cancel":
            self.proTable["command"] = 0x03
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "reservation_start":
            self.proTable["command"] = 0x04
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "reservation_set":
            self.proTable["command"] = 0x05
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "finish":
            self.proTable["command"] = 0x06
        elif lua_table.get(self.keyTable["KEY_COMMAND"]) == "auto_dispenser_setting_change":
            self.proTable["command"] = 0x07
        
        # Mode
        if lua_table.get(self.keyTable["KEY_MODE"]) == "none":
            self.proTable["mode"] = 0x00
        elif lua_table.get(self.keyTable["KEY_MODE"]) == "wash_dry":
            self.proTable["mode"] = 0x01
        elif lua_table.get(self.keyTable["KEY_MODE"]) == "wash":
            self.proTable["mode"] = 0x02
        elif lua_table.get(self.keyTable["KEY_MODE"]) == "dry":
            self.proTable["mode"] = 0x03
        elif lua_table.get(self.keyTable["KEY_MODE"]) == "clean_care":
            self.proTable["mode"] = 0x04
        elif lua_table.get(self.keyTable["KEY_MODE"]) == "care":
            self.proTable["mode"] = 0x05
        
        # Program
        if lua_table.get(self.keyTable["KEY_PROGRAM"]) == "none":
            self.proTable["program"] = 0x00
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "standard":
            self.proTable["program"] = 0x01
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "tub_clean":
            self.proTable["program"] = 0x02
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "fast":
            self.proTable["program"] = 0x03
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "careful":
            self.proTable["program"] = 0x04
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "sixty_wash":
            self.proTable["program"] = 0x05
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "blanket":
            self.proTable["program"] = 0x06
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "delicate":
            self.proTable["program"] = 0x07
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "tub_clean_dry":
            self.proTable["program"] = 0x08
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "memory":
            self.proTable["program"] = 0x09
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "sterilization":
            self.proTable["program"] = 0x0A
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "mute":
            self.proTable["program"] = 0x0B
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "soft":
            self.proTable["program"] = 0x0C
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "delicate_dryer":
            self.proTable["program"] = 0x0D
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "soak":
            self.proTable["program"] = 0x0E
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "odor_eliminating":
            self.proTable["program"] = 0x0F
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "empty":
            self.proTable["program"] = 0x10
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "degerm":
            self.proTable["program"] = 0x11
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "auto_care":
            self.proTable["program"] = 0x12
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "auto_twice_wash":
            self.proTable["program"] = 0x13
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "prewash_plus":
            self.proTable["program"] = 0x14
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_wash_and_dry":
            self.proTable["program"] = 0x15
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_dry_with_rotation":
            self.proTable["program"] = 0x16
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_dry_without_rotation":
            self.proTable["program"] = 0x17
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "forty_five_wash":
            self.proTable["program"] = 0x18
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "fragrant_and_delicate":
            self.proTable["program"] = 0x1C
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "tick_extermination":
            self.proTable["program"] = 0x1D
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "pollen":
            self.proTable["program"] = 0x1E
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "app_course_1":
            self.proTable["program"] = 0x21
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "app_course_2":
            self.proTable["program"] = 0x22
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "app_course_3":
            self.proTable["program"] = 0x23
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "app_course":
            self.proTable["program"] = 0x24
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_wash":
            self.proTable["program"] = 0x25
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_without_rotation":
            self.proTable["program"] = 0x26
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_with_rotation":
            self.proTable["program"] = 0x27
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_deodorize_without_rotation":
            self.proTable["program"] = 0x28
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "uv_deodorize_with_rotation":
            self.proTable["program"] = 0x29
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "60_tub_clean":
            self.proTable["program"] = 0x30
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "tub_clean_wash_dry":
            self.proTable["program"] = 0x32
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "sheets":
            self.proTable["program"] = 0x51
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "lace_curtain":
            self.proTable["program"] = 0x52
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "towel":
            self.proTable["program"] = 0x53
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "fleece":
            self.proTable["program"] = 0x54
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "school_uniform_or_washable":
            self.proTable["program"] = 0x55
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "slacks_skirt":
            self.proTable["program"] = 0x56
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "jeans":
            self.proTable["program"] = 0x57
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "cap":
            self.proTable["program"] = 0x58
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "down_jacket":
            self.proTable["program"] = 0x59
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "bet_putt":
            self.proTable["program"] = 0x5A
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "functional_underwear":
            self.proTable["program"] = 0x5B
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "reusable_bag":
            self.proTable["program"] = 0x5C
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "duvet":
            self.proTable["program"] = 0x5D
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "t_shirt_recovery":
            self.proTable["program"] = 0x5E
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "sports_wear":
            self.proTable["program"] = 0x5F
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "light_dirt":
            self.proTable["program"] = 0x81
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "wash_thoroughly_and_rinse":
            self.proTable["program"] = 0x82
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "quick_wash_and_dry":
            self.proTable["program"] = 0x83
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "yellowing_off":
            self.proTable["program"] = 0x84
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "disinfection_clothing":
            self.proTable["program"] = 0x85
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "keep_water_temperature":
            self.proTable["program"] = 0x86
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "prewash":
            self.proTable["program"] = 0x87
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "super_concentrated_soak":
            self.proTable["program"] = 0x91
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "no_rinse_and_delicate":
            self.proTable["program"] = 0x92
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "t_shirt_recovery_pro":
            self.proTable["program"] = 0x93
        elif lua_table.get(self.keyTable["KEY_PROGRAM"]) == "customize":
            self.proTable["program"] = 0xA0
        
        # Reservation and time settings
        if lua_table.get(self.keyTable["KEY_RESERVATION_HOUR"]) is not None:
            self.proTable["reservationHour"] = string_to_int(lua_table.get(self.keyTable["KEY_RESERVATION_HOUR"]))
        if lua_table.get(self.keyTable["KEY_RESERVATION_MIN"]) is not None:
            self.proTable["reservationMin"] = string_to_int(lua_table.get(self.keyTable["KEY_RESERVATION_MIN"]))
        if lua_table.get(self.keyTable["KEY_TIME_HOUR"]) is not None:
            self.proTable["timeHour"] = string_to_int(lua_table.get(self.keyTable["KEY_TIME_HOUR"]))
        if lua_table.get(self.keyTable["KEY_TIME_MIN"]) is not None:
            self.proTable["timeMin"] = string_to_int(lua_table.get(self.keyTable["KEY_TIME_MIN"]))
        if lua_table.get(self.keyTable["KEY_TIME_SEC"]) is not None:
            self.proTable["timeSec"] = string_to_int(lua_table.get(self.keyTable["KEY_TIME_SEC"]))
        
        # Wash time
        if lua_table.get(self.keyTable["KEY_WASH_TIME"]) is not None:
            update_property_of_wash_time("washTime", lua_table.get(self.keyTable["KEY_WASH_TIME"]))
        
        # Other settings
        if lua_table.get(self.keyTable["KEY_RINSE_POUR"]) is not None:
            self.proTable["rinsePour"] = string_to_int(lua_table.get(self.keyTable["KEY_RINSE_POUR"]))
        if lua_table.get(self.keyTable["KEY_DEHYDRATION_TIME"]) is not None:
            self.proTable["dehydrationTime"] = string_to_int(lua_table.get(self.keyTable["KEY_DEHYDRATION_TIME"]))
        if lua_table.get(self.keyTable["KEY_DRY"]) is not None:
            self.proTable["dry"] = string_to_int(lua_table.get(self.keyTable["KEY_DRY"]))
        
        # Wash rinse
        update_property_of_wash_rise("washRinse", lua_table.get(self.keyTable["KEY_WASH_RISE"]))
        
        # UFB
        update_property_of_ubf("ufb", lua_table.get(self.keyTable["KEY_UFB"]))
        
        # Temperature
        if lua_table.get(self.keyTable["KEY_TEMPERATURE"]) is not None:
            self.proTable["temperature"] = string_to_int(lua_table.get(self.keyTable["KEY_TEMPERATURE"]))
        
        # Lock
        if lua_table.get(self.keyTable["KEY_LOCK"]) == "on":
            self.proTable["lock"] = 0x01
        elif lua_table.get(self.keyTable["KEY_LOCK"]) == "off":
            self.proTable["lock"] = 0x00
        
        # Tub auto clean
        if lua_table.get(self.keyTable["KEY_TUB_AUTO_CLEAN"]) == "on":
            self.proTable["tubAutoClean"] = 0x02
        elif lua_table.get(self.keyTable["KEY_TUB_AUTO_CLEAN"]) == "off":
            self.proTable["tubAutoClean"] = 0x00
        
        # Buzzer
        if lua_table.get(self.keyTable["KEY_BUZZER"]) == "on":
            self.proTable["buzzer"] = 0x04
        elif lua_table.get(self.keyTable["KEY_BUZZER"]) == "off":
            self.proTable["buzzer"] = 0x00
        
        # Rinse mode
        if lua_table.get(self.keyTable["KEY_RINSE_MODE"]) == "on":
            self.proTable["rinseMode"] = 0x08
        elif lua_table.get(self.keyTable["KEY_RINSE_MODE"]) == "off":
            self.proTable["rinseMode"] = 0x00
        
        # Low noise
        if lua_table.get(self.keyTable["KEY_LOW_NOISE"]) == "on":
            self.proTable["lowNoise"] = 0x10
        elif lua_table.get(self.keyTable["KEY_LOW_NOISE"]) == "off":
            self.proTable["lowNoise"] = 0x00
        
        # Energy saving
        if lua_table.get(self.keyTable["KEY_ENERGY_SAVING"]) == "on":
            self.proTable["energySaving"] = 0x20
        elif lua_table.get(self.keyTable["KEY_ENERGY_SAVING"]) == "off":
            self.proTable["energySaving"] = 0x00
        
        # Hot water fifteen
        if lua_table.get(self.keyTable["KEY_HOT_WATER_FIFTEEN"]) == "on":
            self.proTable["hotWaterFifteen"] = 0x40
        elif lua_table.get(self.keyTable["KEY_HOT_WATER_FIFTEEN"]) == "off":
            self.proTable["hotWaterFifteen"] = 0x00
        
        # Dry finish adjust
        if lua_table.get(self.keyTable["KEY_DRY_FINISH_ADJUST"]) is not None:
            self.proTable["dryFinishAdjust"] = string_to_int(lua_table.get(self.keyTable["KEY_DRY_FINISH_ADJUST"]))
        
        # Spin rotate adjust
        if lua_table.get(self.keyTable["KEY_SPIN_ROTATE_ADJUST"]) is not None:
            self.proTable["spinRotateAdjust"] = string_to_int(lua_table.get(self.keyTable["KEY_SPIN_ROTATE_ADJUST"]))
        
        # Fungus protect
        if lua_table.get(self.keyTable["KEY_FUNGUS_PROTECT"]) == "on":
            self.proTable["fungusProtect"] = 0x20
        elif lua_table.get(self.keyTable["KEY_FUNGUS_PROTECT"]) == "off":
            self.proTable["fungusProtect"] = 0x00
        
        # Drain bubble protect
        if lua_table.get(self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]) == "on":
            self.proTable["drainBubbleProtect"] = 0x40
        elif lua_table.get(self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]) == "off":
            self.proTable["drainBubbleProtect"] = 0x00
        
        # Default dry
        if lua_table.get(self.keyTable["KEY_DEFAULT_DRY"]) == "speed":
            self.proTable["defaultDry"] = 0x01
        elif lua_table.get(self.keyTable["KEY_DEFAULT_DRY"]) == "energy_saving":
            self.proTable["defaultDry"] = 0x00
        elif lua_table.get(self.keyTable["KEY_DEFAULT_DRY"]) == "power_saving":
            self.proTable["defaultDry"] = 0x02
        
        # Detergent remain explanation
        if lua_table.get(self.keyTable["KEY_DETERGENT_REMAIN_EXPLANATION"]) is not None:
            self.proTable["detergentRemainExplanation"] = string_to_int(lua_table.get(self.keyTable["KEY_DETERGENT_REMAIN_EXPLANATION"]))
        
        # Detergent setting
        if lua_table.get(self.keyTable["KEY_DETERGENT_SETTING"]) == "on":
            self.proTable["detergentSetting"] = 0x01
        elif lua_table.get(self.keyTable["KEY_DETERGENT_SETTING"]) == "off":
            self.proTable["detergentSetting"] = 0x00
        
        # Softner remain explanation
        if lua_table.get(self.keyTable["KEY_SOFTNER_REMAIN_EXPLANATION"]) is not None:
            self.proTable["softnerRemainExplanation"] = string_to_int(lua_table.get(self.keyTable["KEY_SOFTNER_REMAIN_EXPLANATION"]))
        
        # Softner setting
        if lua_table.get(self.keyTable["KEY_SOFTNER_SETTING"]) == "on":
            self.proTable["softnerSetting"] = 0x01
        elif lua_table.get(self.keyTable["KEY_SOFTNER_SETTING"]) == "off":
            self.proTable["softnerSetting"] = 0x00
        
        # Detergent name
        if lua_table.get(self.keyTable["KEY_DETERGENT_NAME"]) is not None:
            self.proTable["detergentName"] = string_to_int(lua_table.get(self.keyTable["KEY_DETERGENT_NAME"]))
        
        # Softner name
        if lua_table.get(self.keyTable["KEY_SOFTNER_NAME"]) is not None:
            self.proTable["softnerName"] = string_to_int(lua_table.get(self.keyTable["KEY_SOFTNER_NAME"]))
        
        # Detergent measure
        if lua_table.get(self.keyTable["KEY_DETERGENT_MEASURE"]) is not None:
            self.proTable["detergentMeasure"] = string_to_int(lua_table.get(self.keyTable["KEY_DETERGENT_MEASURE"]))
        
        # Softner measure
        if lua_table.get(self.keyTable["KEY_SOFTNER_MEASURE"]) is not None:
            self.proTable["softnerMeasure"] = string_to_int(lua_table.get(self.keyTable["KEY_SOFTNER_MEASURE"]))
        
        # Function type
        if lua_table.get(self.keyTable["KEY_FUNCTION_TYPE"]) == "app_course_receive":
            self.proTable["functionType"] = 0x10
        else:
            self.proTable["functionType"] = 0x00
        
        # Response status
        if lua_table.get("response_status") is not None:
            self.proTable["response_status"] = string_to_int(lua_table.get("response_status"))
        
        # Last app course number
        if lua_table.get("last_app_course_number") is not None:
            self.proTable["last_app_course_number"] = string_to_int(lua_table.get("last_app_course_number"))
        
        # Update wash course properties
        update_property_of_program("wash_course_one_program", lua_table.get("wash_course_one_program"))
        update_property_of_wash_time("wash_course_one_wash_time", lua_table.get("wash_course_one_wash_time"))
        if lua_table.get("wash_course_one_rinse_pour") is not None:
            self.proTable["wash_course_one_rinse_pour"] = string_to_int(lua_table.get("wash_course_one_rinse_pour"))
        if lua_table.get("wash_course_one_dehydration_time") is not None:
            self.proTable["wash_course_one_dehydration_time"] = string_to_int(lua_table.get("wash_course_one_dehydration_time"))
        if lua_table.get("wash_course_one_dry") is not None:
            self.proTable["wash_course_one_dry"] = string_to_int(lua_table.get("wash_course_one_dry"))
        if lua_table.get("wash_course_one_temperature") is not None:
            self.proTable["wash_course_one_temperature"] = string_to_int(lua_table.get("wash_course_one_temperature"))
        update_property_of_wash_rise("wash_course_one_wash_rinse", lua_table.get("wash_course_one_wash_rinse"))
        update_property_of_ubf("wash_course_one_ufb", lua_table.get("wash_course_one_ufb"))
        update_property_of_program("wash_course_one_base_program", lua_table.get("wash_course_one_base_program"))
        
        update_property_of_program("wash_course_two_program", lua_table.get("wash_course_two_program"))
        update_property_of_wash_time("wash_course_two_wash_time", lua_table.get("wash_course_two_wash_time"))
        if lua_table.get("wash_course_two_rinse_pour") is not None:
            self.proTable["wash_course_two_rinse_pour"] = string_to_int(lua_table.get("wash_course_two_rinse_pour"))
        if lua_table.get("wash_course_two_dehydration_time") is not None:
            self.proTable["wash_course_two_dehydration_time"] = string_to_int(lua_table.get("wash_course_two_dehydration_time"))
        if lua_table.get("wash_course_two_dry") is not None:
            self.proTable["wash_course_two_dry"] = string_to_int(lua_table.get("wash_course_two_dry"))
        if lua_table.get("wash_course_two_temperature") is not None:
            self.proTable["wash_course_two_temperature"] = string_to_int(lua_table.get("wash_course_two_temperature"))
        update_property_of_wash_rise("wash_course_two_wash_rinse", lua_table.get("wash_course_two_wash_rinse"))
        update_property_of_ubf("wash_course_two_ufb", lua_table.get("wash_course_two_ufb"))
        update_property_of_program("wash_course_two_base_program", lua_table.get("wash_course_two_base_program"))
        
        update_property_of_program("wash_course_three_program", lua_table.get("wash_course_three_program"))
        update_property_of_wash_time("wash_course_three_wash_time", lua_table.get("wash_course_three_wash_time"))
        if lua_table.get("wash_course_three_rinse_pour") is not None:
            self.proTable["wash_course_three_rinse_pour"] = string_to_int(lua_table.get("wash_course_three_rinse_pour"))
        if lua_table.get("wash_course_three_dehydration_time") is not None:
            self.proTable["wash_course_three_dehydration_time"] = string_to_int(lua_table.get("wash_course_three_dehydration_time"))
        if lua_table.get("wash_course_three_dry") is not None:
            self.proTable["wash_course_three_dry"] = string_to_int(lua_table.get("wash_course_three_dry"))
        if lua_table.get("wash_course_three_temperature") is not None:
            self.proTable["wash_course_three_temperature"] = string_to_int(lua_table.get("wash_course_three_temperature"))
        update_property_of_wash_rise("wash_course_three_wash_rinse", lua_table.get("wash_course_three_wash_rinse"))
        update_property_of_ubf("wash_course_three_ufb", lua_table.get("wash_course_three_ufb"))
        update_property_of_program("wash_course_three_base_program", lua_table.get("wash_course_three_base_program"))
        
        update_property_of_program("wash_dry_course_one_program", lua_table.get("wash_dry_course_one_program"))
        update_property_of_wash_time("wash_dry_course_one_wash_time", lua_table.get("wash_dry_course_one_wash_time"))
        if lua_table.get("wash_dry_course_one_rinse_pour") is not None:
            self.proTable["wash_dry_course_one_rinse_pour"] = string_to_int(lua_table.get("wash_dry_course_one_rinse_pour"))
        if lua_table.get("wash_dry_course_one_dehydration_time") is not None:
            self.proTable["wash_dry_course_one_dehydration_time"] = string_to_int(lua_table.get("wash_dry_course_one_dehydration_time"))
        if lua_table.get("wash_dry_course_one_dry") is not None:
            self.proTable["wash_dry_course_one_dry"] = string_to_int(lua_table.get("wash_dry_course_one_dry"))
        if lua_table.get("wash_dry_course_one_temperature") is not None:
            self.proTable["wash_dry_course_one_temperature"] = string_to_int(lua_table.get("wash_dry_course_one_temperature"))
        self.update_property_of_wash_rise("wash_dry_course_one_wash_rinse", lua_table.get("wash_dry_course_one_wash_rinse"))
        self.update_property_of_ubf("wash_dry_course_one_ufb", lua_table.get("wash_dry_course_one_ufb"))
        self.update_property_of_program("wash_dry_course_one_base_program", lua_table.get("wash_dry_course_one_base_program"))
        
        self.update_property_of_program("wash_dry_course_two_program", lua_table.get("wash_dry_course_two_program"))
        self.update_property_of_wash_time("wash_dry_course_two_wash_time", lua_table.get("wash_dry_course_two_wash_time"))
        if lua_table.get("wash_dry_course_two_rinse_pour") is not None:
            self.proTable["wash_dry_course_two_rinse_pour"] = string_to_int(lua_table.get("wash_dry_course_two_rinse_pour"))
        if lua_table.get("wash_dry_course_two_dehydration_time") is not None:
            self.proTable["wash_dry_course_two_dehydration_time"] = string_to_int(lua_table.get("wash_dry_course_two_dehydration_time"))
        if lua_table.get("wash_dry_course_two_dry") is not None:
            self.proTable["wash_dry_course_two_dry"] = string_to_int(lua_table.get("wash_dry_course_two_dry"))
        if lua_table.get("wash_dry_course_two_temperature") is not None:
            self.proTable["wash_dry_course_two_temperature"] = string_to_int(lua_table.get("wash_dry_course_two_temperature"))
        self.update_property_of_wash_rise("wash_dry_course_two_wash_rinse", lua_table.get("wash_dry_course_two_wash_rinse"))
        self.update_property_of_ubf("wash_dry_course_two_ufb", lua_table.get("wash_dry_course_two_ufb"))
        self.update_property_of_program("wash_dry_course_two_base_program", lua_table.get("wash_dry_course_two_base_program"))
        
        self.update_property_of_program("wash_dry_course_three_program", lua_table.get("wash_dry_course_three_program"))
        self.update_property_of_wash_time("wash_dry_course_three_wash_time", lua_table.get("wash_dry_course_three_wash_time"))
        if lua_table.get("wash_dry_course_three_rinse_pour") is not None:
            self.proTable["wash_dry_course_three_rinse_pour"] = string_to_int(lua_table.get("wash_dry_course_three_rinse_pour"))
        if lua_table.get("wash_dry_course_three_dehydration_time") is not None:
            self.proTable["wash_dry_course_three_dehydration_time"] = string_to_int(lua_table.get("wash_dry_course_three_dehydration_time"))
        if lua_table.get("wash_dry_course_three_dry") is not None:
            self.proTable["wash_dry_course_three_dry"] = string_to_int(lua_table.get("wash_dry_course_three_dry"))
        if lua_table.get("wash_dry_course_three_temperature") is not None:
            self.proTable["wash_dry_course_three_temperature"] = string_to_int(lua_table.get("wash_dry_course_three_temperature"))
        self.update_property_of_wash_rise("wash_dry_course_three_wash_rinse", lua_table.get("wash_dry_course_three_wash_rinse"))
        self.update_property_of_ubf("wash_dry_course_three_ufb", lua_table.get("wash_dry_course_three_ufb"))
        self.update_property_of_program("wash_dry_course_three_base_program", lua_table.get("wash_dry_course_three_base_program"))

    def updateGlobalPropertyValueByByte(self, messageBytes):
        if len(messageBytes) == 0:
            return None
        if (self.dataType == 0x02) or (self.dataType == 0x03):
            if messageBytes[0] == 0x00:
                self.proTable["command"] = messageBytes[1]
                self.proTable["mode"] = messageBytes[2]
                self.proTable["program"] = messageBytes[3]
                self.proTable["reservationMin"] = messageBytes[4]
                self.proTable["reservationHour"] = messageBytes[5]
                self.proTable["timeSec"] = messageBytes[6]
                self.proTable["timeMin"] = messageBytes[7]
                self.proTable["timeHour"] = messageBytes[8]
                self.proTable["washTime"] = messageBytes[9]
                self.proTable["rinsePour"] = messageBytes[10]
                self.proTable["dehydrationTime"] = messageBytes[11]
                self.proTable["dry"] = messageBytes[12]
                self.proTable["washRinse"] = messageBytes[13] & 0x07
                self.proTable["ufb"] = messageBytes[13] & 0x80
                self.proTable["temperature"] = messageBytes[14]
                self.proTable["lock"] = messageBytes[15] & 0x01
                self.proTable["tubAutoClean"] = messageBytes[15] & 0x02
                self.proTable["buzzer"] = messageBytes[15] & 0x04
                self.proTable["rinseMode"] = messageBytes[15] & 0x08
                self.proTable["lowNoise"] = messageBytes[15] & 0x10
                self.proTable["energySaving"] = messageBytes[15] & 0x20
                self.proTable["hotWaterFifteen"] = messageBytes[15] & 0x40
                self.proTable["dryFinishAdjust"] = messageBytes[16] & 0x07
                self.proTable["spinRotateAdjust"] = (messageBytes[16] >> 3) & 0x03
                self.proTable["fungusProtect"] = messageBytes[16] & 0x20
                self.proTable["drainBubbleProtect"] = messageBytes[16] & 0x40
                self.proTable["defaultDry"] = messageBytes[17] & 0x03
                self.proTable["processInfo"] = messageBytes[18]
                self.proTable["processDetail"] = messageBytes[19]
                self.proTable["error"] = (messageBytes[21] << 8) + messageBytes[20]
                self.proTable["machineStatus"] = messageBytes[22]
                self.proTable["remainTime"] = (
                    messageBytes[26] * 16777216 + messageBytes[25] * 65536 + 
                    messageBytes[24] * 256 + messageBytes[23]
                )
                self.proTable["doorOpen"] = messageBytes[27] & 0x01
                self.proTable["remainTimeAdjust"] = messageBytes[27] & 0x02
                self.proTable["drainFilterClean"] = messageBytes[27] & 0x04
                self.proTable["tubHighHot"] = messageBytes[27] & 0x08
                self.proTable["waterHighTemperature"] = messageBytes[27] & 0x10
                self.proTable["tubWaterExist"] = messageBytes[27] & 0x20
                self.proTable["overCapacity"] = messageBytes[27] & 0x40
                self.proTable["drainFilterCare"] = messageBytes[28] & 0x01
                self.proTable["dryFilterClean"] = messageBytes[28] & 0x02
                self.proTable["appCourseNumber"] = (messageBytes[28] >> 2) & 0x0f
                self.proTable["reservationMode"] = messageBytes[29]
                self.proTable["operationWashTime"] = messageBytes[30]
                self.proTable["operationWashRinseTimes"] = messageBytes[31]
                self.proTable["operationWashSpinTime"] = messageBytes[32]
                self.proTable["operationWashDryerTime"] = messageBytes[33]
                self.proTable["operationWashDryerRinseTimes"] = messageBytes[34]
                self.proTable["operationWashDryerSpinTime"] = messageBytes[35]
                self.proTable["operationWashDryerDrySet"] = messageBytes[36]
                self.proTable["operationDryerDrySet"] = messageBytes[37]
                self.proTable["detergentRemain"] = messageBytes[38] & 0x0F
                temp = messageBytes[38] >> 4
                self.proTable["detergentRemainExplanation"] = temp & 0x07
                self.proTable["detergentSetting"] = messageBytes[38] >> 7
                self.proTable["softnerRemain"] = messageBytes[39] & 0x0F
                temp = messageBytes[39] >> 4
                self.proTable["softnerRemainExplanation"] = temp & 0x07
                self.proTable["softnerSetting"] = messageBytes[39] >> 7
                self.proTable["detergentName"] = messageBytes[40]
                self.proTable["softnerName"] = messageBytes[41]
                self.proTable["detergentMeasure"] = messageBytes[42]
                self.proTable["softnerMeasure"] = messageBytes[43]
                self.proTable["beginProcess"] = messageBytes[44]
                self.proTable["reservationTimeEarliestHour"] = (messageBytes[45] >> 3) & 0x1F
                self.proTable["reservationTimeEarliestMin"] = messageBytes[45] & 0x07
                self.proTable["reservationTimeLatestHour"] = (messageBytes[46] >> 3) & 0x1F
                self.proTable["reservationTimeLatestMin"] = messageBytes[46] & 0x07
        if (self.dataType == 0x03) or (self.dataType == 0x06):
            if messageBytes[0] == 0xFE:
                self.proTable["errorCode"] = (messageBytes[2] << 8) + messageBytes[1]
                self.proTable["errorMin"] = messageBytes[3]
                self.proTable["errorHour"] = messageBytes[4]
                self.proTable["errorDay"] = messageBytes[5]
                self.proTable["errorMonth"] = messageBytes[6]
                self.proTable["errorYear"] = (messageBytes[8] << 8) + messageBytes[7]
                firmTab = []
                for i in range(1, 8):
                    firmTab.append(messageBytes[8 + i])
                firmTabStr = table2string(firmTab)
                self.proTable["firm"] = string2hexstring(firmTabStr)
                mnTab = []
                for i in range(1, 19):
                    mnTab.append(messageBytes[15 + i])
                mnTabStr = table2string(mnTab)
                self.proTable["machineName"] = string2hexstring(mnTabStr)
                e2promTab = []
                for i in range(1, 1026):
                    e2promTab.append(messageBytes[33 + i])
                e2promTabStr = table2string(e2promTab)
                self.proTable["e2prom"] = string2hexstring(e2promTabStr)
                self.proTable["reservationHour"] = messageBytes[1060]
                self.proTable["reservationMin"] = messageBytes[1061]
                self.proTable["dryClothWeight"] = messageBytes[1062]
                self.proTable["wetClothWeight"] = messageBytes[1063]
                self.proTable["operationStartTimeHour"] = messageBytes[1064]
                self.proTable["operationStartTimeMin"] = messageBytes[1065]
                self.proTable["operationEndTimeHour"] = messageBytes[1066]
                self.proTable["operationEndTimeMin"] = messageBytes[1067]
                self.proTable["remainTimeHour"] = messageBytes[1068]
                self.proTable["remainTimeMin"] = messageBytes[1069]
                self.proTable["operationTimeHour"] = messageBytes[1070]
                self.proTable["operationTimeMin"] = messageBytes[1071]
                self.proTable["presenceDetergent"] = messageBytes[1072]
        if (self.dataType == 0x04):
            if messageBytes[0] == 0x00:
                self.proTable["command"] = messageBytes[1]
                self.proTable["mode"] = messageBytes[2]
                self.proTable["program"] = messageBytes[3]
                self.proTable["reservationMin"] = messageBytes[4]
                self.proTable["reservationHour"] = messageBytes[5]
                self.proTable["timeSec"] = messageBytes[6]
                self.proTable["timeMin"] = messageBytes[7]
                self.proTable["timeHour"] = messageBytes[8]
                self.proTable["washTime"] = messageBytes[9]
                self.proTable["rinsePour"] = messageBytes[10]
                self.proTable["dehydrationTime"] = messageBytes[11]
                self.proTable["dry"] = messageBytes[12]
                self.proTable["washRinse"] = messageBytes[13] & 0x07
                self.proTable["ufb"] = messageBytes[13] & 0x80
                self.proTable["temperature"] = messageBytes[14]
                self.proTable["lock"] = messageBytes[15] & 0x01
                self.proTable["tubAutoClean"] = messageBytes[15] & 0x02
                self.proTable["buzzer"] = messageBytes[15] & 0x04
                self.proTable["rinseMode"] = messageBytes[15] & 0x08
                self.proTable["lowNoise"] = messageBytes[15] & 0x10
                self.proTable["energySaving"] = messageBytes[15] & 0x20
                self.proTable["hotWaterFifteen"] = messageBytes[15] & 0x40
                self.proTable["dryFinishAdjust"] = messageBytes[16] & 0x07
                self.proTable["spinRotateAdjust"] = (messageBytes[16] >> 3) & 0x03
                self.proTable["fungusProtect"] = messageBytes[16] & 0x20
                self.proTable["drainBubbleProtect"] = messageBytes[16] & 0x40
                self.proTable["defaultDry"] = messageBytes[17] & 0x03
                self.proTable["processInfo"] = messageBytes[18]
                self.proTable["processDetail"] = messageBytes[19]
                self.proTable["error"] = (messageBytes[21] << 8) + messageBytes[20]
                self.proTable["machineStatus"] = messageBytes[22]
                self.proTable["remainTime"] = (
                    messageBytes[26] * 16777216 + messageBytes[25] * 65536 + 
                    messageBytes[24] * 256 + messageBytes[23]
                )
                self.proTable["doorOpen"] = messageBytes[27] & 0x01
                self.proTable["remainTimeAdjust"] = messageBytes[27] & 0x02
                self.proTable["drainFilterClean"] = messageBytes[27] & 0x04
                self.proTable["tubHighHot"] = messageBytes[27] & 0x08
                self.proTable["waterHighTemperature"] = messageBytes[27] & 0x10
                self.proTable["tubWaterExist"] = messageBytes[27] & 0x20
                self.proTable["overCapacity"] = messageBytes[27] & 0x40
                self.proTable["drainFilterCare"] = messageBytes[28] & 0x01
                self.proTable["dryFilterClean"] = messageBytes[28] & 0x02
                self.proTable["appCourseNumber"] = (messageBytes[28] >> 2) & 0x0f
                self.proTable["reservationMode"] = messageBytes[29]
                self.proTable["operationWashTime"] = messageBytes[30]
                self.proTable["operationWashRinseTimes"] = messageBytes[31]
                self.proTable["operationWashSpinTime"] = messageBytes[32]
                self.proTable["operationWashDryerTime"] = messageBytes[33]
                self.proTable["operationWashDryerRinseTimes"] = messageBytes[34]
                self.proTable["operationWashDryerSpinTime"] = messageBytes[35]
                self.proTable["operationWashDryerDrySet"] = messageBytes[36]
                self.proTable["operationDryerDrySet"] = messageBytes[37]
                self.proTable["detergentRemain"] = messageBytes[38] & 0x0F
                temp = messageBytes[38] >> 4
                self.proTable["detergentRemainExplanation"] = temp & 0x07
                self.proTable["detergentSetting"] = messageBytes[38] >> 7
                self.proTable["softnerRemain"] = messageBytes[39] & 0x0F
                temp = messageBytes[39] >> 4
                self.proTable["softnerRemainExplanation"] = temp & 0x07
                self.proTable["softnerSetting"] = messageBytes[39] >> 7
                self.proTable["detergentName"] = messageBytes[40]
                self.proTable["softnerName"] = messageBytes[41]
                self.proTable["detergentMeasure"] = messageBytes[42]
                self.proTable["softnerMeasure"] = messageBytes[43]
                self.proTable["beginProcess"] = messageBytes[44]
                self.proTable["reservationTimeEarliestHour"] = (messageBytes[45] >> 3) & 0x1F
                self.proTable["reservationTimeEarliestMin"] = messageBytes[45] & 0x07
                self.proTable["reservationTimeLatestHour"] = (messageBytes[46] >> 3) & 0x1F
                self.proTable["reservationTimeLatestMin"] = messageBytes[46] & 0x07
        if (self.dataType == 0x06):
            if messageBytes[0] == 0x20:
                self.proTable["mode"] = messageBytes[1]
                self.proTable["program"] = messageBytes[2]
                self.proTable["washTime"] = messageBytes[3]
                self.proTable["rinsePour"] = messageBytes[4]
                self.proTable["dehydrationTime"] = messageBytes[5]
                self.proTable["dry"] = messageBytes[6]
                self.proTable["temperature"] = messageBytes[7]
                self.proTable["washRinse"] = messageBytes[8] & 0x07
                self.proTable["ufb"] = messageBytes[8] & 0x80
                self.proTable["courseConfirmNumber"] = messageBytes[9]
        if (self.dataType == 0x02) or (self.dataType == 0x04) or (self.dataType == 0x05):
            if messageBytes[0] == 0x10:
                self.proTable["response_status"] = messageBytes[1]
                self.proTable["last_app_course_number"] = messageBytes[2]
                self.proTable["wash_course_one_program"] = messageBytes[11]
                self.proTable["wash_course_one_wash_time"] = messageBytes[12]
                self.proTable["wash_course_one_rinse_pour"] = messageBytes[13]
                self.proTable["wash_course_one_dehydration_time"] = messageBytes[14]
                self.proTable["wash_course_one_dry"] = messageBytes[15]
                self.proTable["wash_course_one_temperature"] = messageBytes[16]
                self.proTable["wash_course_one_wash_rinse"] = messageBytes[17] & 0x07
                self.proTable["wash_course_one_ufb"] = messageBytes[17] & 0x80
                self.proTable["wash_course_one_base_program"] = messageBytes[18]
                self.proTable["wash_course_two_program"] = messageBytes[21]
                self.proTable["wash_course_two_wash_time"] = messageBytes[22]
                self.proTable["wash_course_two_rinse_pour"] = messageBytes[23]
                self.proTable["wash_course_two_dehydration_time"] = messageBytes[24]
                self.proTable["wash_course_two_dry"] = messageBytes[25]
                self.proTable["wash_course_two_temperature"] = messageBytes[26]
                self.proTable["wash_course_two_wash_rinse"] = messageBytes[27] & 0x07
                self.proTable["wash_course_two_ufb"] = messageBytes[27] & 0x80
                self.proTable["wash_course_two_base_program"] = messageBytes[28]
                self.proTable["wash_course_three_program"] = messageBytes[31]
                self.proTable["wash_course_three_wash_time"] = messageBytes[32]
                self.proTable["wash_course_three_rinse_pour"] = messageBytes[33]
                self.proTable["wash_course_three_dehydration_time"] = messageBytes[34]
                self.proTable["wash_course_three_dry"] = messageBytes[35]
                self.proTable["wash_course_three_temperature"] = messageBytes[36]
                self.proTable["wash_course_three_wash_rinse"] = messageBytes[37] & 0x07
                self.proTable["wash_course_three_ufb"] = messageBytes[37] & 0x80
                self.proTable["wash_course_three_base_program"] = messageBytes[38]
                self.proTable["wash_dry_course_one_program"] = messageBytes[41]
                self.proTable["wash_dry_course_one_wash_time"] = messageBytes[42]
                self.proTable["wash_dry_course_one_rinse_pour"] = messageBytes[43]
                self.proTable["wash_dry_course_one_dehydration_time"] = messageBytes[44]
                self.proTable["wash_dry_course_one_dry"] = messageBytes[45]
                self.proTable["wash_dry_course_one_temperature"] = messageBytes[46]
                self.proTable["wash_dry_course_one_wash_rinse"] = messageBytes[47] & 0x07
                self.proTable["wash_dry_course_one_ufb"] = messageBytes[47] & 0x80
                self.proTable["wash_dry_course_one_base_program"] = messageBytes[48]
                self.proTable["wash_dry_course_two_program"] = messageBytes[51]
                self.proTable["wash_dry_course_two_wash_time"] = messageBytes[52]
                self.proTable["wash_dry_course_two_rinse_pour"] = messageBytes[53]
                self.proTable["wash_dry_course_two_dehydration_time"] = messageBytes[54]
                self.proTable["wash_dry_course_two_dry"] = messageBytes[55]
                self.proTable["wash_dry_course_two_temperature"] = messageBytes[56]
                self.proTable["wash_dry_course_two_wash_rinse"] = messageBytes[57] & 0x07
                self.proTable["wash_dry_course_two_ufb"] = messageBytes[57] & 0x80
                self.proTable["wash_dry_course_two_base_program"] = messageBytes[58]
                self.proTable["wash_dry_course_three_program"] = messageBytes[61]
                self.proTable["wash_dry_course_three_wash_time"] = messageBytes[62]
                self.proTable["wash_dry_course_three_rinse_pour"] = messageBytes[63]
                self.proTable["wash_dry_course_three_dehydration_time"] = messageBytes[64]
                self.proTable["wash_dry_course_three_dry"] = messageBytes[65]
                self.proTable["wash_dry_course_three_temperature"] = messageBytes[66]
                self.proTable["wash_dry_course_three_wash_rinse"] = messageBytes[67] & 0x07
                self.proTable["wash_dry_course_three_ufb"] = messageBytes[67] & 0x80
                self.proTable["wash_dry_course_three_base_program"] = messageBytes[68]
        if (self.dataType == 0x05):
            if messageBytes[0] == 0x30:
                self.proTable["inventoryUsageType"] = messageBytes[1]
                self.proTable["inventoryUsageAmount"] = messageBytes[2]
                self.proTable["inventoryUsageAccumulatedAmount"] = (messageBytes[3] << 8) + messageBytes[4]

    def assembleMode(self, streams, key, value):
        if value == 0x00:
            streams[key] = "none"
        elif value == 0x01:
            streams[key] = "wash_dry"
        elif value == 0x02:
            streams[key] = "wash"
        elif value == 0x03:
            streams[key] = "dry"
        elif value == 0x04:
            streams[key] = "clean_care"
        elif value == 0x05:
            streams[key] = "care"

    def assembleProgram(self, streams, key, value):
        if value == 0x00:
            streams[key] = "none"
        elif value == 0x01:
            streams[key] = "standard"
        elif value == 0x02:
            streams[key] = "tub_clean"
        elif value == 0x03:
            streams[key] = "fast"
        elif value == 0x04:
            streams[key] = "careful"
        elif value == 0x05:
            streams[key] = "sixty_wash"
        elif value == 0x06:
            streams[key] = "blanket"
        elif value == 0x07:
            streams[key] = "delicate"
        elif value == 0x08:
            streams[key] = "tub_clean_dry"
        elif value == 0x09:
            streams[key] = "memory"
        elif value == 0x0A:
            streams[key] = "sterilization"
        elif value == 0x0B:
            streams[key] = "mute"
        elif value == 0x0C:
            streams[key] = "soft"
        elif value == 0x0D:
            streams[key] = "delicate_dryer"
        elif value == 0x0E:
            streams[key] = "soak"
        elif value == 0x0F:
            streams[key] = "odor_eliminating"
        elif value == 0x10:
            streams[key] = "empty"
        elif value == 0x11:
            streams[key] = "degerm"
        elif value == 0x12:
            streams[key] = "auto_care"
        elif value == 0x13:
            streams[key] = "auto_twice_wash"
        elif value == 0x14:
            streams[key] = "prewash_plus"
        elif value == 0x15:
            streams[key] = "uv_wash_and_dry"
        elif value == 0x16:
            streams[key] = "uv_dry_with_rotation"
        elif value == 0x17:
            streams[key] = "uv_dry_without_rotation"
        elif value == 0x18:
            streams[key] = "forty_five_wash"
        elif value == 0x1C:
            streams[key] = "fragrant_and_delicate"
        elif value == 0x1D:
            streams[key] = "tick_extermination"
        elif value == 0x1E:
            streams[key] = "pollen"
        elif value == 0x21:
            streams[key] = "app_course_1"
        elif value == 0x22:
            streams[key] = "app_course_2"
        elif value == 0x23:
            streams[key] = "app_course_3"
        elif value == 0x24:
            streams[key] = "app_course"
        elif value == 0x25:
            streams[key] = "uv_wash"
        elif value == 0x26:
            streams[key] = "uv_without_rotation"
        elif value == 0x27:
            streams[key] = "uv_with_rotation"
        elif value == 0x28:
            streams[key] = "uv_deodorize_without_rotation"
        elif value == 0x29:
            streams[key] = "uv_deodorize_with_rotation"
        elif value == 0x30:
            streams[key] = "60_tub_clean"
        elif value == 0x51:
            streams[key] = "sheets"
        elif value == 0x52:
            streams[key] = "lace_curtain"
        elif value == 0x53:
            streams[key] = "towel"
        elif value == 0x54:
            streams[key] = "fleece"
        elif value == 0x55:
            streams[key] = "school_uniform_or_washable"
        elif value == 0x56:
            streams[key] = "slacks_skirt"
        elif value == 0x57:
            streams[key] = "jeans"
        elif value == 0x58:
            streams[key] = "cap"
        elif value == 0x59:
            streams[key] = "down_jacket"
        elif value == 0x5A:
            streams[key] = "bet_putt"
        elif value == 0x5B:
            streams[key] = "functional_underwear"
        elif value == 0x5C:
            streams[key] = "reusable_bag"
        elif value == 0x5D:
            streams[key] = "duvet"
        elif value == 0x5E:
            streams[key] = "t_shirt_recovery"
        elif value == 0x5F:
            streams[key] = "sports_wear"
        elif value == 0x81:
            streams[key] = "light_dirt"
        elif value == 0x82:
            streams[key] = "wash_thoroughly_and_rinse"
        elif value == 0x83:
            streams[key] = "quick_wash_and_dry"
        elif value == 0x84:
            streams[key] = "yellowing_off"
        elif value == 0x85:
            streams[key] = "disinfection_clothing"
        elif value == 0x86:
            streams[key] = "keep_water_temperature"
        elif value == 0x87:
            streams[key] = "prewash"
        elif value == 0x91:
            streams[key] = "super_concentrated_soak"
        elif value == 0x92:
            streams[key] = "no_rinse_and_delicate"
        elif value == 0x93:
            streams[key] = "t_shirt_recovery_pro"
        elif value == 0xA0:
            streams[key] = "customize"

    def assembleWashTime(self, streams, key, value):
        if value == 0x81:
            streams[key] = 1 * 60
        elif value == 0x82:
            streams[key] = 2 * 60
        elif value == 0x83:
            streams[key] = 3 * 60
        elif value == 0x84:
            streams[key] = 4 * 60
        elif value == 0x85:
            streams[key] = 5 * 60
        elif value == 0x86:
            streams[key] = 6 * 60
        elif value == 0x87:
            streams[key] = 7 * 60
        elif value == 0x88:
            streams[key] = 8 * 60
        elif value == 0x89:
            streams[key] = 9 * 60
        elif value == 0x8A:
            streams[key] = 10 * 60
        elif value == 0x8B:
            streams[key] = 11 * 60
        elif value == 0x8C:
            streams[key] = 12 * 60
        else:
            streams[key] = value

    def assembleWashRinse(self, streams, key, value):
        if value == 0x00:
            streams[key] = "none"
        elif value == 0x01:
            streams[key] = "wash"
        elif value == 0x02:
            streams[key] = "wash_to_rinse"
        elif value == 0x03:
            streams[key] = "rinse"

    def assembleUFB(self, streams, key, value):
        if value == 0x00:
            streams[key] = "off"
        elif value == 0x80:
            streams[key] = "on"

    def assembleJsonByGlobalProperty(self):
        streams = {}
        streams[self.keyTable["KEY_VERSION"]] = self.version
        if (self.subDataType == 0x00):
            streams[self.keyTable["KEY_FUNCTION_TYPE"]] = "base"
            if self.proTable["command"] == 0x01:
                streams[self.keyTable["KEY_COMMAND"]] = "temporary_stop"
            elif self.proTable["command"] == 0x02:
                streams[self.keyTable["KEY_COMMAND"]] = "reservation_fix"
            elif self.proTable["command"] == 0x03:
                streams[self.keyTable["KEY_COMMAND"]] = "reservation_cancel"
            elif self.proTable["command"] == 0x04:
                streams[self.keyTable["KEY_COMMAND"]] = "reservation_start"
            elif self.proTable["command"] == 0x05:
                streams[self.keyTable["KEY_COMMAND"]] = "reservation_set"
            elif self.proTable["command"] == 0x06:
                streams[self.keyTable["KEY_COMMAND"]] = "finish"
            elif self.proTable["command"] == 0x07:
                streams[self.keyTable["KEY_COMMAND"]] = "auto_dispenser_setting_change"
            else:
                streams[self.keyTable["KEY_COMMAND"]] = "none"
            if self.proTable["mode"] == 0x00:
                streams[self.keyTable["KEY_MODE"]] = "none"
            elif self.proTable["mode"] == 0x01:
                streams[self.keyTable["KEY_MODE"]] = "wash_dry"
            elif self.proTable["mode"] == 0x02:
                streams[self.keyTable["KEY_MODE"]] = "wash"
            elif self.proTable["mode"] == 0x03:
                streams[self.keyTable["KEY_MODE"]] = "dry"
            elif self.proTable["mode"] == 0x04:
                streams[self.keyTable["KEY_MODE"]] = "clean_care"
            elif self.proTable["mode"] == 0x05:
                streams[self.keyTable["KEY_MODE"]] = "care"
            if self.proTable["program"] == 0x00:
                streams[self.keyTable["KEY_PROGRAM"]] = "none"
            elif self.proTable["program"] == 0x01:
                streams[self.keyTable["KEY_PROGRAM"]] = "standard"
            elif self.proTable["program"] == 0x02:
                streams[self.keyTable["KEY_PROGRAM"]] = "tub_clean"
            elif self.proTable["program"] == 0x03:
                streams[self.keyTable["KEY_PROGRAM"]] = "fast"
            elif self.proTable["program"] == 0x04:
                streams[self.keyTable["KEY_PROGRAM"]] = "careful"
            elif self.proTable["program"] == 0x05:
                streams[self.keyTable["KEY_PROGRAM"]] = "sixty_wash"
            elif self.proTable["program"] == 0x06:
                streams[self.keyTable["KEY_PROGRAM"]] = "blanket"
            elif self.proTable["program"] == 0x07:
                streams[self.keyTable["KEY_PROGRAM"]] = "delicate"
            elif self.proTable["program"] == 0x08:
                streams[self.keyTable["KEY_PROGRAM"]] = "tub_clean_dry"
            elif self.proTable["program"] == 0x09:
                streams[self.keyTable["KEY_PROGRAM"]] = "memory"
            elif self.proTable["program"] == 0x0A:
                streams[self.keyTable["KEY_PROGRAM"]] = "sterilization"
            elif self.proTable["program"] == 0x0B:
                streams[self.keyTable["KEY_PROGRAM"]] = "mute"
            elif self.proTable["program"] == 0x0C:
                streams[self.keyTable["KEY_PROGRAM"]] = "soft"
            elif self.proTable["program"] == 0x0D:
                streams[self.keyTable["KEY_PROGRAM"]] = "delicate_dryer"
            elif self.proTable["program"] == 0x0E:
                streams[self.keyTable["KEY_PROGRAM"]] = "soak"
            elif self.proTable["program"] == 0x0F:
                streams[self.keyTable["KEY_PROGRAM"]] = "odor_eliminating"
            elif self.proTable["program"] == 0x10:
                streams[self.keyTable["KEY_PROGRAM"]] = "empty"
            elif self.proTable["program"] == 0x11:
                streams[self.keyTable["KEY_PROGRAM"]] = "degerm"
            elif self.proTable["program"] == 0x12:
                streams[self.keyTable["KEY_PROGRAM"]] = "auto_care"
            elif self.proTable["program"] == 0x13:
                streams[self.keyTable["KEY_PROGRAM"]] = "auto_twice_wash"
            elif self.proTable["program"] == 0x14:
                streams[self.keyTable["KEY_PROGRAM"]] = "prewash_plus"
            elif self.proTable["program"] == 0x15:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_wash_and_dry"
            elif self.proTable["program"] == 0x16:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_dry_with_rotation"
            elif self.proTable["program"] == 0x17:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_dry_without_rotation"
            elif self.proTable["program"] == 0x18:
                streams[self.keyTable["KEY_PROGRAM"]] = "forty_five_wash"
            elif self.proTable["program"] == 0x1C:
                streams[self.keyTable["KEY_PROGRAM"]] = "fragrant_and_delicate"
            elif self.proTable["program"] == 0x1D:
                streams[self.keyTable["KEY_PROGRAM"]] = "tick_extermination"
            elif self.proTable["program"] == 0x1E:
                streams[self.keyTable["KEY_PROGRAM"]] = "pollen"
            elif self.proTable["program"] == 0x21:
                streams[self.keyTable["KEY_PROGRAM"]] = "app_course_1"
            elif self.proTable["program"] == 0x22:
                streams[self.keyTable["KEY_PROGRAM"]] = "app_course_2"
            elif self.proTable["program"] == 0x23:
                streams[self.keyTable["KEY_PROGRAM"]] = "app_course_3"
            elif self.proTable["program"] == 0x24:
                streams[self.keyTable["KEY_PROGRAM"]] = "app_course"
            elif self.proTable["program"] == 0x25:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_wash"
            elif self.proTable["program"] == 0x26:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_without_rotation"
            elif self.proTable["program"] == 0x27:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_with_rotation"
            elif self.proTable["program"] == 0x28:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_deodorize_without_rotation"
            elif self.proTable["program"] == 0x29:
                streams[self.keyTable["KEY_PROGRAM"]] = "uv_deodorize_with_rotation"
            elif self.proTable["program"] == 0x30:
                streams[self.keyTable["KEY_PROGRAM"]] = "60_tub_clean"
            elif self.proTable["program"] == 0x32:
                streams[self.keyTable["KEY_PROGRAM"]] = "tub_clean_wash_dry"
            elif self.proTable["program"] == 0x51:
                streams[self.keyTable["KEY_PROGRAM"]] = "sheets"
            elif self.proTable["program"] == 0x52:
                streams[self.keyTable["KEY_PROGRAM"]] = "lace_curtain"
            elif self.proTable["program"] == 0x53:
                streams[self.keyTable["KEY_PROGRAM"]] = "towel"
            elif self.proTable["program"] == 0x54:
                streams[self.keyTable["KEY_PROGRAM"]] = "fleece"
            elif self.proTable["program"] == 0x55:
                streams[self.keyTable["KEY_PROGRAM"]] = "school_uniform_or_washable"
            elif self.proTable["program"] == 0x56:
                streams[self.keyTable["KEY_PROGRAM"]] = "slacks_skirt"
            elif self.proTable["program"] == 0x57:
                streams[self.keyTable["KEY_PROGRAM"]] = "jeans"
            elif self.proTable["program"] == 0x58:
                streams[self.keyTable["KEY_PROGRAM"]] = "cap"
            elif self.proTable["program"] == 0x59:
                streams[self.keyTable["KEY_PROGRAM"]] = "down_jacket"
            elif self.proTable["program"] == 0x5A:
                streams[self.keyTable["KEY_PROGRAM"]] = "bet_putt"
            elif self.proTable["program"] == 0x5B:
                streams[self.keyTable["KEY_PROGRAM"]] = "functional_underwear"
            elif self.proTable["program"] == 0x5C:
                streams[self.keyTable["KEY_PROGRAM"]] = "reusable_bag"
            elif self.proTable["program"] == 0x5D:
                streams[self.keyTable["KEY_PROGRAM"]] = "duvet"
            elif self.proTable["program"] == 0x5E:
                streams[self.keyTable["KEY_PROGRAM"]] = "t_shirt_recovery"
            elif self.proTable["program"] == 0x5F:
                streams[self.keyTable["KEY_PROGRAM"]] = "sports_wear"
            elif self.proTable["program"] == 0x81:
                streams[self.keyTable["KEY_PROGRAM"]] = "light_dirt"
            elif self.proTable["program"] == 0x82:
                streams[self.keyTable["KEY_PROGRAM"]] = "wash_thoroughly_and_rinse"
            elif self.proTable["program"] == 0x83:
                streams[self.keyTable["KEY_PROGRAM"]] = "quick_wash_and_dry"
            elif self.proTable["program"] == 0x84:
                streams[self.keyTable["KEY_PROGRAM"]] = "yellowing_off"
            elif self.proTable["program"] == 0x85:
                streams[self.keyTable["KEY_PROGRAM"]] = "disinfection_clothing"
            elif self.proTable["program"] == 0x86:
                streams[self.keyTable["KEY_PROGRAM"]] = "keep_water_temperature"
            elif self.proTable["program"] == 0x87:
                streams[self.keyTable["KEY_PROGRAM"]] = "prewash"
            elif self.proTable["program"] == 0x91:
                streams[self.keyTable["KEY_PROGRAM"]] = "super_concentrated_soak"
            elif self.proTable["program"] == 0x92:
                streams[self.keyTable["KEY_PROGRAM"]] = "no_rinse_and_delicate"
            elif self.proTable["program"] == 0x93:
                streams[self.keyTable["KEY_PROGRAM"]] = "t_shirt_recovery_pro"
            elif self.proTable["program"] == 0xA0:
                streams[self.keyTable["KEY_PROGRAM"]] = "customize"
            streams[self.keyTable["KEY_RESERVATION_HOUR"]] = self.proTable["reservationHour"]
            streams[self.keyTable["KEY_RESERVATION_MIN"]] = self.proTable["reservationMin"]
            streams[self.keyTable["KEY_TIME_HOUR"]] = self.proTable["timeHour"]
            streams[self.keyTable["KEY_TIME_MIN"]] = self.proTable["timeMin"]
            streams[self.keyTable["KEY_TIME_SEC"]] = self.proTable["timeSec"]
            self.assembleWashTime(streams, self.keyTable["KEY_WASH_TIME"], self.proTable["washTime"])
            streams[self.keyTable["KEY_RINSE_POUR"]] = self.proTable["rinsePour"]
            streams[self.keyTable["KEY_DEHYDRATION_TIME"]] = self.proTable["dehydrationTime"]
            streams[self.keyTable["KEY_DRY"]] = self.proTable["dry"]
            self.assembleWashRinse(streams, self.keyTable["KEY_WASH_RISE"], self.proTable["washRinse"])
            self.assembleUFB(streams, self.keyTable["KEY_UFB"], self.proTable["ufb"])
            streams[self.keyTable["KEY_TEMPERATURE"]] = self.proTable["temperature"]
            if self.proTable["lock"] == 0x01:
                streams[self.keyTable["KEY_LOCK"]] = "on"
            elif self.proTable["lock"] == 0x00:
                streams[self.keyTable["KEY_LOCK"]] = "off"
            if self.proTable["tubAutoClean"] == 0x02:
                streams[self.keyTable["KEY_TUB_AUTO_CLEAN"]] = "on"
            elif self.proTable["tubAutoClean"] == 0x00:
                streams[self.keyTable["KEY_TUB_AUTO_CLEAN"]] = "off"
            if self.proTable["buzzer"] == 0x04:
                streams[self.keyTable["KEY_BUZZER"]] = "on"
            elif self.proTable["buzzer"] == 0x00:
                streams[self.keyTable["KEY_BUZZER"]] = "off"
            if self.proTable["rinseMode"] == 0x08:
                streams[self.keyTable["KEY_RINSE_MODE"]] = "on"
            elif self.proTable["rinseMode"] == 0x00:
                streams[self.keyTable["KEY_RINSE_MODE"]] = "off"
            if self.proTable["lowNoise"] == 0x10:
                streams[self.keyTable["KEY_LOW_NOISE"]] = "on"
            elif self.proTable["lowNoise"] == 0x00:
                streams[self.keyTable["KEY_LOW_NOISE"]] = "off"
            if self.proTable["energySaving"] == 0x20:
                streams[self.keyTable["KEY_ENERGY_SAVING"]] = "on"
            elif self.proTable["energySaving"] == 0x00:
                streams[self.keyTable["KEY_ENERGY_SAVING"]] = "off"
            if self.proTable["hotWaterFifteen"] == 0x40:
                streams[self.keyTable["KEY_HOT_WATER_FIFTEEN"]] = "on"
            elif self.proTable["hotWaterFifteen"] == 0x00:
                streams[self.keyTable["KEY_HOT_WATER_FIFTEEN"]] = "off"
            streams[self.keyTable["KEY_DRY_FINISH_ADJUST"]] = self.proTable["dryFinishAdjust"]
            streams[self.keyTable["KEY_SPIN_ROTATE_ADJUST"]] = self.proTable["spinRotateAdjust"]
            if self.proTable["fungusProtect"] == 0x20:
                streams[self.keyTable["KEY_FUNGUS_PROTECT"]] = "on"
            elif self.proTable["fungusProtect"] == 0x00:
                streams[self.keyTable["KEY_FUNGUS_PROTECT"]] = "off"
            if self.proTable["drainBubbleProtect"] == 0x40:
                streams[self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]] = "on"
            elif self.proTable["drainBubbleProtect"] == 0x00:
                streams[self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]] = "off"
            if self.proTable["defaultDry"] == 0x01:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "speed"
            elif self.proTable["defaultDry"] == 0x00:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "energy_saving"
            elif self.proTable["defaultDry"] == 0x02:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "power_saving"
            if (self.proTable["processInfo"] & 0x02) == 0x02:
                streams[self.keyTable["KEY_PROCESS_INFO_WASH"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_WASH"]] = "no"
            if (self.proTable["processInfo"] & 0x04) == 0x04:
                streams[self.keyTable["KEY_PROCESS_INFO_RINSE"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_RINSE"]] = "no"
            if (self.proTable["processInfo"] & 0x08) == 0x08:
                streams[self.keyTable["KEY_PROCESS_INFO_SPIN"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_SPIN"]] = "no"
            if (self.proTable["processInfo"] & 0x10) == 0x10:
                streams[self.keyTable["KEY_PROCESS_INFO_DRY"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_DRY"]] = "no"
            if (self.proTable["processInfo"] & 0x20) == 0x20:
                streams[self.keyTable["KEY_PROCESS_INFO_SOFT_KEEP"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_SOFT_KEEP"]] = "no"
            streams[self.keyTable["KEY_PROCESS_DETAIL"]] = self.proTable["processDetail"]
            streams[self.keyTable["KEY_ERROR"]] = self.proTable["error"]
            if self.proTable["machineStatus"] == 0x00:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "power_off"
            elif self.proTable["machineStatus"] == 0x01:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "power_on"
            elif self.proTable["machineStatus"] == 0x02:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "running"
            elif self.proTable["machineStatus"] == 0x03:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "pause"
            elif self.proTable["machineStatus"] == 0x04:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "finish"
            elif self.proTable["machineStatus"] == 0x50:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "pop_up"
            streams[self.keyTable["KEY_REMAIN_TIME"]] = self.proTable["remainTime"]
            if (self.proTable["doorOpen"] == 0x01):
                streams[self.keyTable["KEY_DOOR_OPEN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DOOR_OPEN"]] = 0x00
            if (self.proTable["remainTimeAdjust"] == 0x02):
                streams[self.keyTable["KEY_REMAIN_TIME_ADJUST"]] = 0x01
            else:
                streams[self.keyTable["KEY_REMAIN_TIME_ADJUST"]] = 0x00
            if (self.proTable["drainFilterClean"] == 0x04):
                streams[self.keyTable["KEY_DRAIN_FILTER_CLEAN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DRAIN_FILTER_CLEAN"]] = 0x00
            if (self.proTable["tubHighHot"] == 0x08):
                streams[self.keyTable["KEY_TUB_HIGH_HOT"]] = 0x01
            else:
                streams[self.keyTable["KEY_TUB_HIGH_HOT"]] = 0x00
            if (self.proTable["waterHighTemperature"] == 0x10):
                streams[self.keyTable["KEY_WATER_HIGH_TEMPERATURE"]] = 0x01
            else:
                streams[self.keyTable["KEY_WATER_HIGH_TEMPERATURE"]] = 0x00
            if (self.proTable["tubWaterExist"] == 0x20):
                streams[self.keyTable["KEY_TUB_WATER_EXIST"]] = 0x01
            else:
                streams[self.keyTable["KEY_TUB_WATER_EXIST"]] = 0x00
            if (self.proTable["overCapacity"] == 0x40):
                streams[self.keyTable["KEY_OVER_CAPACITY"]] = 0x01
            else:
                streams[self.keyTable["KEY_OVER_CAPACITY"]] = 0x00
            streams[self.keyTable["KEY_DRAIN_FILTER_CARE"]] = self.proTable["drainFilterCare"]
            if (self.proTable["dryFilterClean"] == 0x02):
                streams[self.keyTable["KEY_DRY_FILTER_CLEAN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DRY_FILTER_CLEAN"]] = 0x00
            streams[self.keyTable["KEY_APP_COURSE_NUMBER"]] = self.proTable["appCourseNumber"]
            streams[self.keyTable["KEY_RESERVATION_MODE"]] = self.proTable["reservationMode"]
            streams[self.keyTable["KEY_OPERATION_WASH_TIME"]] = self.proTable["operationWashTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_RINSE_TIMES"]] = self.proTable["operationWashRinseTimes"]
            streams[self.keyTable["KEY_OPERATION_WASH_SPIN_TIME"]] = self.proTable["operationWashSpinTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_TIME"]] = self.proTable["operationWashDryerTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_RINSE_TIMES"]] = self.proTable["operationWashDryerRinseTimes"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_SPIN_TIME"]] = self.proTable["operationWashDryerSpinTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_DRY_SET"]] = self.proTable["operationWashDryerDrySet"]
            streams[self.keyTable["KEY_OPERATION_DRYER_DRY_SET"]] = self.proTable["operationDryerDrySet"]
            streams[self.keyTable["KEY_DETERGENT_REMAIN"]] = self.proTable["detergentRemain"]
            streams[self.keyTable["KEY_DETERGENT_REMAIN_EXPLANATION"]] = self.proTable["detergentRemainExplanation"]
            if (self.proTable["detergentSetting"] == 0x01):
                streams[self.keyTable["KEY_DETERGENT_SETTING"]] = "on"
            else:
                streams[self.keyTable["KEY_DETERGENT_SETTING"]] = "off"
            streams[self.keyTable["KEY_SOFTNER_REMAIN"]] = self.proTable["softnerRemain"]
            streams[self.keyTable["KEY_SOFTNER_REMAIN_EXPLANATION"]] = self.proTable["softnerRemainExplanation"]
            if (self.proTable["softnerSetting"] == 0x01):
                streams[self.keyTable["KEY_SOFTNER_SETTING"]] = "on"
            else:
                streams[self.keyTable["KEY_SOFTNER_SETTING"]] = "off"
            streams[self.keyTable["KEY_DETERGENT_NAME"]] = self.proTable["detergentName"]
            streams[self.keyTable["KEY_SOFTNER_NAME"]] = self.proTable["softnerName"]
            streams[self.keyTable["KEY_DETERGENT_MEASURE"]] = self.proTable["detergentMeasure"]
            streams[self.keyTable["KEY_SOFTNER_MEASURE"]] = self.proTable["softnerMeasure"]
            if (self.proTable["beginProcess"] & 0x02) == 0x02:
                streams[self.keyTable["KEY_BEGIN_PROCESS_WASH"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_WASH"]] = "no"
            if (self.proTable["beginProcess"] & 0x04) == 0x04:
                streams[self.keyTable["KEY_BEGIN_PROCESS_RINSE"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_RINSE"]] = "no"
            if (self.proTable["beginProcess"] & 0x08) == 0x08:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SPIN"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SPIN"]] = "no"
            if (self.proTable["beginProcess"] & 0x10) == 0x10:
                streams[self.keyTable["KEY_BEGIN_PROCESS_DRY"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_DRY"]] = "no"
            if (self.proTable["beginProcess"] & 0x20) == 0x20:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SOFT_KEEP"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SOFT_KEEP"]] = "no"
            streams[self.keyTable["KEY_RESERVATION_TIME_EARLIEST_HOUR"]] = self.proTable["reservationTimeEarliestHour"]
            streams[self.keyTable["KEY_RESERVATION_TIME_EARLIEST_MIN"]] = self.proTable["reservationTimeEarliestMin"] * 10
            streams[self.keyTable["KEY_RESERVATION_TIME_LATEST_HOUR"]] = self.proTable["reservationTimeLatestHour"]
            streams[self.keyTable["KEY_RESERVATION_TIME_LATEST_MIN"]] = self.proTable["reservationTimeLatestMin"] * 10
        elif (self.subDataType == 0x20):
            streams[self.keyTable["KEY_FUNCTION_TYPE"]] = "app_course_confirm"
            self.assembleMode(streams, "course_confirm_mode", self.proTable["mode"])
            self.assembleProgram(streams, "course_confirm_program", self.proTable["program"])
            self.assembleWashTime(streams, "course_confirm_wash_time", self.proTable["washTime"])
            streams["course_confirm_rinse_pour"] = self.proTable["rinsePour"]
            streams["course_confirm_dehydration_time"] = self.proTable["dehydrationTime"]
            streams["course_confirm_dry"] = self.proTable["dry"]
            streams["course_confirm_temperature"] = self.proTable["temperature"]
            self.assembleWashRinse(streams, "course_confirm_wash_rinse", self.proTable["washRinse"])
            self.assembleUFB(streams, "course_confirm_ufb", self.proTable["ufb"])
            streams["course_confirm_number"] = self.proTable["courseConfirmNumber"]
        elif (self.subDataType == 0x10):
            streams[self.keyTable.KEY_FUNCTION_TYPE] = "app_course_receive"
            self.assembleProgram(streams, "wash_course_one_program", self.proTable["wash_course_one_program"])
            self.assembleWashTime(streams, "wash_course_one_wash_time", self.proTable["wash_course_one_wash_time"])
            streams["wash_course_one_rinse_pour"] = self.proTable["wash_course_one_rinse_pour"]
            streams["wash_course_one_dehydration_time"] = self.proTable["wash_course_one_dehydration_time"]
            streams["wash_course_one_dry"] = self.proTable["wash_course_one_dry"]
            streams["wash_course_one_temperature"] = self.proTable["wash_course_one_temperature"]
            self.assembleWashRinse(streams, "wash_course_one_wash_rinse", self.proTable["wash_course_one_wash_rinse"])
            self.assembleUFB(streams, "wash_course_one_ufb", self.proTable["wash_course_one_ufb"])
            self.assembleProgram(streams, "wash_course_one_base_program", self.proTable["wash_course_one_base_program"])
            self.assembleProgram(streams, "wash_course_two_program", self.proTable["wash_course_two_program"])
            self.assembleWashTime(streams, "wash_course_two_wash_time", self.proTable["wash_course_two_wash_time"])
            streams["wash_course_two_rinse_pour"] = self.proTable["wash_course_two_rinse_pour"]
            streams["wash_course_two_dehydration_time"] = self.proTable["wash_course_two_dehydration_time"]
            streams["wash_course_two_dry"] = self.proTable["wash_course_two_dry"]
            streams["wash_course_two_temperature"] = self.proTable["wash_course_two_temperature"]
            self.assembleWashRinse(streams, "wash_course_two_wash_rinse", self.proTable["wash_course_two_wash_rinse"])
            self.assembleUFB(streams, "wash_course_two_ufb", self.proTable["wash_course_two_ufb"])
            self.assembleProgram(streams, "wash_course_two_base_program", self.proTable["wash_course_two_base_program"])
            self.assembleProgram(streams, "wash_course_three_program", self.proTable["wash_course_three_program"])
            self.assembleWashTime(streams, "wash_course_three_wash_time", self.proTable["wash_course_three_wash_time"])
            streams["wash_course_three_rinse_pour"] = self.proTable["wash_course_three_rinse_pour"]
            streams["wash_course_three_dehydration_time"] = self.proTable["wash_course_three_dehydration_time"]
            streams["wash_course_three_dry"] = self.proTable["wash_course_three_dry"]
            streams["wash_course_three_temperature"] = self.proTable["wash_course_three_temperature"]
            self.assembleWashRinse(streams, "wash_course_three_wash_rinse", self.proTable["wash_course_three_wash_rinse"])
            self.assembleUFB(streams, "wash_course_three_ufb", self.proTable["wash_course_three_ufb"])
            self.assembleProgram(streams, "wash_course_three_base_program", self.proTable["wash_course_three_base_program"])
            self.assembleProgram(streams, "wash_dry_course_one_program", self.proTable["wash_dry_course_one_program"])
            self.assembleWashTime(streams, "wash_dry_course_one_wash_time", self.proTable["wash_dry_course_one_wash_time"])
            streams["wash_dry_course_one_rinse_pour"] = self.proTable["wash_dry_course_one_rinse_pour"]
            streams["wash_dry_course_one_dehydration_time"] = self.proTable["wash_dry_course_one_dehydration_time"]
            streams["wash_dry_course_one_dry"] = self.proTable["wash_dry_course_one_dry"]
            streams["wash_dry_course_one_temperature"] = self.proTable["wash_dry_course_one_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_one_wash_rinse", self.proTable["wash_dry_course_one_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_one_ufb", self.proTable["wash_dry_course_one_ufb"])
            self.assembleProgram(streams, "wash_dry_course_one_base_program", self.proTable["wash_dry_course_one_base_program"])
            self.assembleProgram(streams, "wash_dry_course_two_program", self.proTable["wash_dry_course_two_program"])
            self.assembleWashTime(streams, "wash_dry_course_two_wash_time", self.proTable["wash_dry_course_two_wash_time"])
            streams["wash_dry_course_two_rinse_pour"] = self.proTable["wash_dry_course_two_rinse_pour"]
            streams["wash_dry_course_two_dehydration_time"] = self.proTable["wash_dry_course_two_dehydration_time"]
            streams["wash_dry_course_two_dry"] = self.proTable["wash_dry_course_two_dry"]
            streams["wash_dry_course_two_temperature"] = self.proTable["wash_dry_course_two_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_two_wash_rinse", self.proTable["wash_dry_course_two_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_two_ufb", self.proTable["wash_dry_course_two_ufb"])
            self.assembleProgram(streams, "wash_dry_course_two_base_program", self.proTable["wash_dry_course_two_base_program"])
            self.assembleProgram(streams, "wash_dry_course_three_program", self.proTable["wash_dry_course_three_program"])
            self.assembleWashTime(streams, "wash_dry_course_three_wash_time", self.proTable["wash_dry_course_three_wash_time"])
            streams["wash_dry_course_three_rinse_pour"] = self.proTable["wash_dry_course_three_rinse_pour"]
            streams["wash_dry_course_three_dehydration_time"] = self.proTable["wash_dry_course_three_dehydration_time"]
            streams["wash_dry_course_three_dry"] = self.proTable["wash_dry_course_three_dry"]
            streams["wash_dry_course_three_temperature"] = self.proTable["wash_dry_course_three_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_three_wash_rinse", self.proTable["wash_dry_course_three_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_three_ufb", self.proTable["wash_dry_course_three_ufb"])
            self.assembleProgram(streams, "wash_dry_course_three_base_program", self.proTable["wash_dry_course_three_base_program"])
            
            streams[self.keyTable["KEY_RESERVATION_HOUR"]] = self.proTable["reservationHour"]
            streams[self.keyTable["KEY_RESERVATION_MIN"]] = self.proTable["reservationMin"]
            streams[self.keyTable["KEY_TIME_HOUR"]] = self.proTable["timeHour"]
            streams[self.keyTable["KEY_TIME_MIN"]] = self.proTable["timeMin"]
            streams[self.keyTable["KEY_TIME_SEC"]] = self.proTable["timeSec"]
            # Convert hex values to minutes for wash time
            if self.proTable["washTime"] == 0x81:
                streams[self.keyTable["KEY_WASH_TIME"]] = 1 * 60
            elif self.proTable["washTime"] == 0x82:
                streams[self.keyTable["KEY_WASH_TIME"]] = 2 * 60
            elif self.proTable["washTime"] == 0x83:
                streams[self.keyTable["KEY_WASH_TIME"]] = 3 * 60
            elif self.proTable["washTime"] == 0x84:
                streams[self.keyTable["KEY_WASH_TIME"]] = 4 * 60
            elif self.proTable["washTime"] == 0x85:
                streams[self.keyTable["KEY_WASH_TIME"]] = 5 * 60
            elif self.proTable["washTime"] == 0x86:
                streams[self.keyTable["KEY_WASH_TIME"]] = 6 * 60
            elif self.proTable["washTime"] == 0x87:
                streams[self.keyTable["KEY_WASH_TIME"]] = 7 * 60
            elif self.proTable["washTime"] == 0x88:
                streams[self.keyTable["KEY_WASH_TIME"]] = 8 * 60
            elif self.proTable["washTime"] == 0x89:
                streams[self.keyTable["KEY_WASH_TIME"]] = 9 * 60
            elif self.proTable["washTime"] == 0x8A:
                streams[self.keyTable["KEY_WASH_TIME"]] = 10 * 60
            elif self.proTable["washTime"] == 0x8B:
                streams[self.keyTable["KEY_WASH_TIME"]] = 11 * 60
            elif self.proTable["washTime"] == 0x8C:
                streams[self.keyTable["KEY_WASH_TIME"]] = 12 * 60
            else:
                streams[self.keyTable["KEY_WASH_TIME"]] = self.proTable["washTime"]
            
            streams[self.keyTable["KEY_RINSE_POUR"]] = self.proTable["rinsePour"]
            streams[self.keyTable["KEY_DEHYDRATION_TIME"]] = self.proTable["dehydrationTime"]
            streams[self.keyTable["KEY_DRY"]] = self.proTable["dry"]
            
            # Map wash rinse values to string representations
            if self.proTable["washRinse"] == 0x00:
                streams[self.keyTable["KEY_WASH_RISE"]] = "none"
            elif self.proTable["washRinse"] == 0x01:
                streams[self.keyTable["KEY_WASH_RISE"]] = "wash"
            elif self.proTable["washRinse"] == 0x02:
                streams[self.keyTable["KEY_WASH_RISE"]] = "wash_to_rinse"
            elif self.proTable["washRinse"] == 0x03:
                streams[self.keyTable["KEY_WASH_RISE"]] = "rinse"
            elif self.proTable["washRinse"] == 0x07:
                streams[self.keyTable["KEY_WASH_RISE"]] = "hidden"
            
            # Map UFB (Ultra Fine Bubble) values
            if self.proTable["ufb"] == 0x00:
                streams[self.keyTable["KEY_UFB"]] = "off"
            elif self.proTable["ufb"] == 0x80:
                streams[self.keyTable["KEY_UFB"]] = "on"
            
            streams[self.keyTable["KEY_TEMPERATURE"]] = self.proTable["temperature"]
            
            # Map binary state values to on/off strings
            if self.proTable["lock"] == 0x01:
                streams[self.keyTable["KEY_LOCK"]] = "on"
            elif self.proTable["lock"] == 0x00:
                streams[self.keyTable["KEY_LOCK"]] = "off"
            
            if self.proTable["tubAutoClean"] == 0x02:
                streams[self.keyTable["KEY_TUB_AUTO_CLEAN"]] = "on"
            elif self.proTable["tubAutoClean"] == 0x00:
                streams[self.keyTable["KEY_TUB_AUTO_CLEAN"]] = "off"
            
            if self.proTable["buzzer"] == 0x04:
                streams[self.keyTable["KEY_BUZZER"]] = "on"
            elif self.proTable["buzzer"] == 0x00:
                streams[self.keyTable["KEY_BUZZER"]] = "off"
            
            if self.proTable["rinseMode"] == 0x08:
                streams[self.keyTable["KEY_RINSE_MODE"]] = "on"
            elif self.proTable["rinseMode"] == 0x00:
                streams[self.keyTable["KEY_RINSE_MODE"]] = "off"
            
            if self.proTable["lowNoise"] == 0x10:
                streams[self.keyTable["KEY_LOW_NOISE"]] = "on"
            elif self.proTable["lowNoise"] == 0x00:
                streams[self.keyTable["KEY_LOW_NOISE"]] = "off"
            
            if self.proTable["energySaving"] == 0x20:
                streams[self.keyTable["KEY_ENERGY_SAVING"]] = "on"
            elif self.proTable["energySaving"] == 0x00:
                streams[self.keyTable["KEY_ENERGY_SAVING"]] = "off"
            
            if self.proTable["hotWaterFifteen"] == 0x40:
                streams[self.keyTable["KEY_HOT_WATER_FIFTEEN"]] = "on"
            elif self.proTable["hotWaterFifteen"] == 0x00:
                streams[self.keyTable["KEY_HOT_WATER_FIFTEEN"]] = "off"
            
            streams[self.keyTable["KEY_DRY_FINISH_ADJUST"]] = self.proTable["dryFinishAdjust"]
            streams[self.keyTable["KEY_SPIN_ROTATE_ADJUST"]] = self.proTable["spinRotateAdjust"]
            
            if self.proTable["fungusProtect"] == 0x20:
                streams[self.keyTable["KEY_FUNGUS_PROTECT"]] = "on"
            elif self.proTable["fungusProtect"] == 0x00:
                streams[self.keyTable["KEY_FUNGUS_PROTECT"]] = "off"
            
            if self.proTable["drainBubbleProtect"] == 0x40:
                streams[self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]] = "on"
            elif self.proTable["drainBubbleProtect"] == 0x00:
                streams[self.keyTable["KEY_DRAIN_BUBBLE_PROTECT"]] = "off"
            
            # Map default dry mode values
            if self.proTable["defaultDry"] == 0x01:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "speed"
            elif self.proTable["defaultDry"] == 0x00:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "energy_saving"
            elif self.proTable["defaultDry"] == 0x02:
                streams[self.keyTable["KEY_DEFAULT_DRY"]] = "power_saving"
            
            # Process info bit flags
            if (self.proTable["processInfo"] & 0x02) == 0x02:
                streams[self.keyTable["KEY_PROCESS_INFO_WASH"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_WASH"]] = "no"
            
            if (self.proTable["processInfo"] & 0x04) == 0x04:
                streams[self.keyTable["KEY_PROCESS_INFO_RINSE"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_RINSE"]] = "no"
            
            if (self.proTable["processInfo"] & 0x08) == 0x08:
                streams[self.keyTable["KEY_PROCESS_INFO_SPIN"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_SPIN"]] = "no"
            
            if (self.proTable["processInfo"] & 0x10) == 0x10:
                streams[self.keyTable["KEY_PROCESS_INFO_DRY"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_DRY"]] = "no"
            
            if (self.proTable["processInfo"] & 0x20) == 0x20:
                streams[self.keyTable["KEY_PROCESS_INFO_SOFT_KEEP"]] = "yes"
            else:
                streams[self.keyTable["KEY_PROCESS_INFO_SOFT_KEEP"]] = "no"
            
            streams[self.keyTable["KEY_PROCESS_DETAIL"]] = self.proTable["processDetail"]
            streams[self.keyTable["KEY_ERROR"]] = self.proTable["error"]
            
            # Map machine status values
            if self.proTable["machineStatus"] == 0x00:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "power_off"
            elif self.proTable["machineStatus"] == 0x01:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "power_on"
            elif self.proTable["machineStatus"] == 0x02:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "running"
            elif self.proTable["machineStatus"] == 0x03:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "pause"
            elif self.proTable["machineStatus"] == 0x04:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "finish"
            elif self.proTable["machineStatus"] == 0x50:
                streams[self.keyTable["KEY_MACHINE_STATUS"]] = "pop_up"
            
            streams[self.keyTable["KEY_REMAIN_TIME"]] = self.proTable["remainTime"]
            
            # Map binary state values to 0/1
            if self.proTable["doorOpen"] == 0x01:
                streams[self.keyTable["KEY_DOOR_OPEN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DOOR_OPEN"]] = 0x00
            
            if self.proTable["remainTimeAdjust"] == 0x02:
                streams[self.keyTable["KEY_REMAIN_TIME_ADJUST"]] = 0x01
            else:
                streams[self.keyTable["KEY_REMAIN_TIME_ADJUST"]] = 0x00
            
            if self.proTable["drainFilterClean"] == 0x04:
                streams[self.keyTable["KEY_DRAIN_FILTER_CLEAN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DRAIN_FILTER_CLEAN"]] = 0x00
            
            if self.proTable["tubHighHot"] == 0x08:
                streams[self.keyTable["KEY_TUB_HIGH_HOT"]] = 0x01
            else:
                streams[self.keyTable["KEY_TUB_HIGH_HOT"]] = 0x00
            
            if self.proTable["waterHighTemperature"] == 0x10:
                streams[self.keyTable["KEY_WATER_HIGH_TEMPERATURE"]] = 0x01
            else:
                streams[self.keyTable["KEY_WATER_HIGH_TEMPERATURE"]] = 0x00
            
            if self.proTable["tubWaterExist"] == 0x20:
                streams[self.keyTable["KEY_TUB_WATER_EXIST"]] = 0x01
            else:
                streams[self.keyTable["KEY_TUB_WATER_EXIST"]] = 0x00
            
            if self.proTable["overCapacity"] == 0x40:
                streams[self.keyTable["KEY_OVER_CAPACITY"]] = 0x01
            else:
                streams[self.keyTable["KEY_OVER_CAPACITY"]] = 0x00
            
            streams[self.keyTable["KEY_DRAIN_FILTER_CARE"]] = self.proTable["drainFilterCare"]
            
            if self.proTable["dryFilterClean"] == 0x02:
                streams[self.keyTable["KEY_DRY_FILTER_CLEAN"]] = 0x01
            else:
                streams[self.keyTable["KEY_DRY_FILTER_CLEAN"]] = 0x00
            
            streams[self.keyTable["KEY_APP_COURSE_NUMBER"]] = self.proTable["appCourseNumber"]
            streams[self.keyTable["KEY_RESERVATION_MODE"]] = self.proTable["reservationMode"]
            streams[self.keyTable["KEY_OPERATION_WASH_TIME"]] = self.proTable["operationWashTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_RINSE_TIMES"]] = self.proTable["operationWashRinseTimes"]
            streams[self.keyTable["KEY_OPERATION_WASH_SPIN_TIME"]] = self.proTable["operationWashSpinTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_TIME"]] = self.proTable["operationWashDryerTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_RINSE_TIMES"]] = self.proTable["operationWashDryerRinseTimes"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_SPIN_TIME"]] = self.proTable["operationWashDryerSpinTime"]
            streams[self.keyTable["KEY_OPERATION_WASH_DRYER_DRY_SET"]] = self.proTable["operationWashDryerDrySet"]
            streams[self.keyTable["KEY_OPERATION_DRYER_DRY_SET"]] = self.proTable["operationDryerDrySet"]
            streams[self.keyTable["KEY_DETERGENT_REMAIN"]] = self.proTable["detergentRemain"]
            streams[self.keyTable["KEY_DETERGENT_REMAIN_EXPLANATION"]] = self.proTable["detergentRemainExplanation"]
            
            if self.proTable["detergentSetting"] == 0x01:
                streams[self.keyTable["KEY_DETERGENT_SETTING"]] = "on"
            else:
                streams[self.keyTable["KEY_DETERGENT_SETTING"]] = "off"
            
            streams[self.keyTable["KEY_SOFTNER_REMAIN"]] = self.proTable["softnerRemain"]
            streams[self.keyTable["KEY_SOFTNER_REMAIN_EXPLANATION"]] = self.proTable["softnerRemainExplanation"]
            
            if self.proTable["softnerSetting"] == 0x01:
                streams[self.keyTable["KEY_SOFTNER_SETTING"]] = "on"
            else:
                streams[self.keyTable["KEY_SOFTNER_SETTING"]] = "off"
            
            streams[self.keyTable["KEY_DETERGENT_NAME"]] = self.proTable["detergentName"]
            streams[self.keyTable["KEY_SOFTNER_NAME"]] = self.proTable["softnerName"]
            streams[self.keyTable["KEY_DETERGENT_MEASURE"]] = self.proTable["detergentMeasure"]
            streams[self.keyTable["KEY_SOFTNER_MEASURE"]] = self.proTable["softnerMeasure"]
            
            # Begin process bit flags
            if (self.proTable["beginProcess"] & 0x02) == 0x02:
                streams[self.keyTable["KEY_BEGIN_PROCESS_WASH"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_WASH"]] = "no"
            
            if (self.proTable["beginProcess"] & 0x04) == 0x04:
                streams[self.keyTable["KEY_BEGIN_PROCESS_RINSE"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_RINSE"]] = "no"
            
            if (self.proTable["beginProcess"] & 0x08) == 0x08:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SPIN"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SPIN"]] = "no"
            
            if (self.proTable["beginProcess"] & 0x10) == 0x10:
                streams[self.keyTable["KEY_BEGIN_PROCESS_DRY"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_DRY"]] = "no"
            
            if (self.proTable["beginProcess"] & 0x20) == 0x20:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SOFT_KEEP"]] = "yes"
            else:
                streams[self.keyTable["KEY_BEGIN_PROCESS_SOFT_KEEP"]] = "no"
            
            streams[self.keyTable["KEY_RESERVATION_TIME_EARLIEST_HOUR"]] = self.proTable["reservationTimeEarliestHour"]
            streams[self.keyTable["KEY_RESERVATION_TIME_EARLIEST_MIN"]] = self.proTable["reservationTimeEarliestMin"] * 10
            streams[self.keyTable["KEY_RESERVATION_TIME_LATEST_HOUR"]] = self.proTable["reservationTimeLatestHour"]
            streams[self.keyTable["KEY_RESERVATION_TIME_LATEST_MIN"]] = self.proTable["reservationTimeLatestMin"] * 10
        elif (self.subDataType == 0x20):
            streams[self.keyTable.KEY_FUNCTION_TYPE] = "app_course_confirm"
            self.assembleMode(streams, "course_confirm_mode", self.proTable["mode"])
            self.assembleProgram(streams, "course_confirm_program", self.proTable["program"])
            self.assembleWashTime(streams, "course_confirm_wash_time", self.proTable["washTime"])
            streams["course_confirm_rinse_pour"] = self.proTable["rinsePour"]
            streams["course_confirm_dehydration_time"] = self.proTable["dehydrationTime"]
            streams["course_confirm_dry"] = self.proTable["dry"]
            streams["course_confirm_temperature"] = self.proTable["temperature"]
            self.assembleWashRinse(streams, "course_confirm_wash_rinse", self.proTable["washRinse"])
            self.assembleUFB(streams, "course_confirm_ufb", self.proTable["ufb"])
            streams["course_confirm_number"] = self.proTable["courseConfirmNumber"]
        elif (self.subDataType == 0x10):
            streams[self.keyTable.KEY_FUNCTION_TYPE] = "app_course_receive"
            self.assembleProgram(streams, "wash_course_one_program", self.proTable["wash_course_one_program"])
            self.assembleWashTime(streams, "wash_course_one_wash_time", self.proTable["wash_course_one_wash_time"])
            streams["wash_course_one_rinse_pour"] = self.proTable["wash_course_one_rinse_pour"]
            streams["wash_course_one_dehydration_time"] = self.proTable["wash_course_one_dehydration_time"]
            streams["wash_course_one_dry"] = self.proTable["wash_course_one_dry"]
            streams["wash_course_one_temperature"] = self.proTable["wash_course_one_temperature"]
            self.assembleWashRinse(streams, "wash_course_one_wash_rinse", self.proTable["wash_course_one_wash_rinse"])
            self.assembleUFB(streams, "wash_course_one_ufb", self.proTable["wash_course_one_ufb"])
            self.assembleProgram(streams, "wash_course_one_base_program", self.proTable["wash_course_one_base_program"])
            self.assembleProgram(streams, "wash_course_two_program", self.proTable["wash_course_two_program"])
            self.assembleWashTime(streams, "wash_course_two_wash_time", self.proTable["wash_course_two_wash_time"])
            streams["wash_course_two_rinse_pour"] = self.proTable["wash_course_two_rinse_pour"]
            streams["wash_course_two_dehydration_time"] = self.proTable["wash_course_two_dehydration_time"]
            streams["wash_course_two_dry"] = self.proTable["wash_course_two_dry"]
            streams["wash_course_two_temperature"] = self.proTable["wash_course_two_temperature"]
            self.assembleWashRinse(streams, "wash_course_two_wash_rinse", self.proTable["wash_course_two_wash_rinse"])
            self.assembleUFB(streams, "wash_course_two_ufb", self.proTable["wash_course_two_ufb"])
            self.assembleProgram(streams, "wash_course_two_base_program", self.proTable["wash_course_two_base_program"])
            self.assembleProgram(streams, "wash_course_three_program", self.proTable["wash_course_three_program"])
            self.assembleWashTime(streams, "wash_course_three_wash_time", self.proTable["wash_course_three_wash_time"])
            streams["wash_course_three_rinse_pour"] = self.proTable["wash_course_three_rinse_pour"]
            streams["wash_course_three_dehydration_time"] = self.proTable["wash_course_three_dehydration_time"]
            streams["wash_course_three_dry"] = self.proTable["wash_course_three_dry"]
            streams["wash_course_three_temperature"] = self.proTable["wash_course_three_temperature"]
            self.assembleWashRinse(streams, "wash_course_three_wash_rinse", self.proTable["wash_course_three_wash_rinse"])
            self.assembleUFB(streams, "wash_course_three_ufb", self.proTable["wash_course_three_ufb"])
            self.assembleProgram(streams, "wash_course_three_base_program", self.proTable["wash_course_three_base_program"])
            self.assembleProgram(streams, "wash_dry_course_one_program", self.proTable["wash_dry_course_one_program"])
            self.assembleWashTime(streams, "wash_dry_course_one_wash_time", self.proTable["wash_dry_course_one_wash_time"])
            streams["wash_dry_course_one_rinse_pour"] = self.proTable["wash_dry_course_one_rinse_pour"]
            streams["wash_dry_course_one_dehydration_time"] = self.proTable["wash_dry_course_one_dehydration_time"]
            streams["wash_dry_course_one_dry"] = self.proTable["wash_dry_course_one_dry"]
            streams["wash_dry_course_one_temperature"] = self.proTable["wash_dry_course_one_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_one_wash_rinse", self.proTable["wash_dry_course_one_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_one_ufb", self.proTable["wash_dry_course_one_ufb"])
            self.assembleProgram(streams, "wash_dry_course_one_base_program", self.proTable["wash_dry_course_one_base_program"])
            self.assembleProgram(streams, "wash_dry_course_two_program", self.proTable["wash_dry_course_two_program"])
            self.assembleWashTime(streams, "wash_dry_course_two_wash_time", self.proTable["wash_dry_course_two_wash_time"])
            streams["wash_dry_course_two_rinse_pour"] = self.proTable["wash_dry_course_two_rinse_pour"]
            streams["wash_dry_course_two_dehydration_time"] = self.proTable["wash_dry_course_two_dehydration_time"]
            streams["wash_dry_course_two_dry"] = self.proTable["wash_dry_course_two_dry"]
            streams["wash_dry_course_two_temperature"] = self.proTable["wash_dry_course_two_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_two_wash_rinse", self.proTable["wash_dry_course_two_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_two_ufb", self.proTable["wash_dry_course_two_ufb"])
            self.assembleProgram(streams, "wash_dry_course_two_base_program", self.proTable["wash_dry_course_two_base_program"])
            self.assembleProgram(streams, "wash_dry_course_three_program", self.proTable["wash_dry_course_three_program"])
            self.assembleWashTime(streams, "wash_dry_course_three_wash_time", self.proTable["wash_dry_course_three_wash_time"])
            streams["wash_dry_course_three_rinse_pour"] = self.proTable["wash_dry_course_three_rinse_pour"]
            streams["wash_dry_course_three_dehydration_time"] = self.proTable["wash_dry_course_three_dehydration_time"]
            streams["wash_dry_course_three_dry"] = self.proTable["wash_dry_course_three_dry"]
            streams["wash_dry_course_three_temperature"] = self.proTable["wash_dry_course_three_temperature"]
            self.assembleWashRinse(streams, "wash_dry_course_three_wash_rinse", self.proTable["wash_dry_course_three_wash_rinse"])
            self.assembleUFB(streams, "wash_dry_course_three_ufb", self.proTable["wash_dry_course_three_ufb"])
            self.assembleProgram(streams, "wash_dry_course_three_base_program", self.proTable["wash_dry_course_three_base_program"])
        elif (self.subDataType == 0x30):
            streams[self.keyTable["KEY_FUNCTION_TYPE"]] = "inventory_usage"
            if (self.proTable["inventoryUsageType"] == 0x02):
                streams["inventory_usage_type"] = "softener"
            else:
                streams["inventory_usage_type"] = "detergent"
            streams["inventory_usage_amount"] = self.proTable["inventoryUsageAmount"]
            streams["inventory_usage_accumulated_amount"] = self.proTable["inventoryUsageAccumulatedAmount"]
        else:
            streams[self.keyTable["KEY_FUNCTION_TYPE"]] = "exception"
            streams["error_code"] = self.proTable["errorCode"]
            streams["error_year"] = self.proTable["errorYear"]
            streams["error_month"] = self.proTable["errorMonth"]
            streams["error_day"] = self.proTable["errorDay"]
            streams["error_hour"] = self.proTable["errorHour"]
            streams["error_min"] = self.proTable["errorMin"]
            streams["firm"] = self.proTable["firm"]
            streams["machine_name"] = self.proTable["machineName"]
            streams["e2prom"] = self.proTable["e2prom"]
            streams["dry_cloth_weight"] = self.proTable["dryClothWeight"]
            streams["wet_cloth_weight"] = self.proTable["wetClothWeight"]
            streams["operation_start_time_hour"] = self.proTable["operationStartTimeHour"]
            streams["operation_start_time_min"] = self.proTable["operationStartTimeMin"]
            streams["operation_end_time_hour"] = self.proTable["operationEndTimeHour"]
            streams["operation_end_time_min"] = self.proTable["operationEndTimeMin"]
            streams["remain_time_hour"] = self.proTable["remainTimeHour"]
            streams["remain_time_min"] = self.proTable["remainTimeMin"]
            streams["operation_time_hour"] = self.proTable["operationTimeHour"]
            streams["operation_time_min"] = self.proTable["operationTimeMin"]
            streams["presence_detergent"] = self.proTable["presenceDetergent"]
        return streams

    def json_to_data(self, json_cmd_str: str) -> str:
        if not json_cmd_str:
            return None

        msg_bytes = []
        json_data = self.decode_json_to_table(json_cmd_str)
        device_sub_type = json_data["deviceinfo"]["deviceSubType"]
        query = json_data.get("query", None)
        control = json_data.get("control", None)
        status = json_data.get("status", None)        

        if control is not None:
            if status is not None:
                self.update_global_property_value_by_json(status)
            if control is not None:
                self.update_global_property_value_by_json(control)

            body_bytes = []
            if self.pro_table["functionType"] == 0x10:
                body_length = 71
                body_bytes = [0xFF] * body_length
                body_bytes[0] = 0x10
                body_bytes[1] = self.pro_table["response_status"]
                body_bytes[2] = self.pro_table["last_app_course_number"]
                # Set wash course one values
                body_bytes[11] = self.pro_table["wash_course_one_program"]
                body_bytes[12] = self.pro_table["wash_course_one_wash_time"]
                body_bytes[13] = self.pro_table["wash_course_one_rinse_pour"]
                body_bytes[14] = self.pro_table["wash_course_one_dehydration_time"]
                body_bytes[15] = self.pro_table["wash_course_one_dry"]
                body_bytes[16] = self.pro_table["wash_course_one_temperature"]
                body_bytes[17] = self.pro_table["wash_course_one_wash_rinse"] | self.pro_table["wash_course_one_ufb"]
                body_bytes[18] = self.pro_table["wash_course_one_base_program"]
                # Set wash course two values
                body_bytes[21] = self.pro_table["wash_course_two_program"]
                body_bytes[22] = self.pro_table["wash_course_two_wash_time"]
                body_bytes[23] = self.pro_table["wash_course_two_rinse_pour"]
                body_bytes[24] = self.pro_table["wash_course_two_dehydration_time"]
                body_bytes[25] = self.pro_table["wash_course_two_dry"]
                body_bytes[26] = self.pro_table["wash_course_two_temperature"]
                body_bytes[27] = self.pro_table["wash_course_two_wash_rinse"] | self.pro_table["wash_course_two_ufb"]
                body_bytes[28] = self.pro_table["wash_course_two_base_program"]
                # Set wash course three values
                body_bytes[31] = self.pro_table["wash_course_three_program"]
                body_bytes[32] = self.pro_table["wash_course_three_wash_time"]
                body_bytes[33] = self.pro_table["wash_course_three_rinse_pour"]
                body_bytes[34] = self.pro_table["wash_course_three_dehydration_time"]
                body_bytes[35] = self.pro_table["wash_course_three_dry"]
                body_bytes[36] = self.pro_table["wash_course_three_temperature"]
                body_bytes[37] = self.pro_table["wash_course_three_wash_rinse"] | self.pro_table["wash_course_three_ufb"]
                body_bytes[38] = self.pro_table["wash_course_three_base_program"]
                # Set wash dry course one values
                body_bytes[41] = self.pro_table["wash_dry_course_one_program"]
                body_bytes[42] = self.pro_table["wash_dry_course_one_wash_time"]
                body_bytes[43] = self.pro_table["wash_dry_course_one_rinse_pour"]
                body_bytes[44] = self.pro_table["wash_dry_course_one_dehydration_time"]
                body_bytes[45] = self.pro_table["wash_dry_course_one_dry"]
                body_bytes[46] = self.pro_table["wash_dry_course_one_temperature"]
                body_bytes[47] = self.pro_table["wash_dry_course_one_wash_rinse"] | self.pro_table["wash_dry_course_one_ufb"]
                body_bytes[48] = self.pro_table["wash_dry_course_one_base_program"]
                # Set wash dry course two values
                body_bytes[51] = self.pro_table["wash_dry_course_two_program"]
                body_bytes[52] = self.pro_table["wash_dry_course_two_wash_time"]
                body_bytes[53] = self.pro_table["wash_dry_course_two_rinse_pour"]
                body_bytes[54] = self.pro_table["wash_dry_course_two_dehydration_time"]
                body_bytes[55] = self.pro_table["wash_dry_course_two_dry"]
                body_bytes[56] = self.pro_table["wash_dry_course_two_temperature"]
                body_bytes[57] = self.pro_table["wash_dry_course_two_wash_rinse"] | self.pro_table["wash_dry_course_two_ufb"]
                body_bytes[58] = self.pro_table["wash_dry_course_two_base_program"]
                # Set wash dry course three values
                body_bytes[61] = self.pro_table["wash_dry_course_three_program"]
                body_bytes[62] = self.pro_table["wash_dry_course_three_wash_time"]
                body_bytes[63] = self.pro_table["wash_dry_course_three_rinse_pour"]
                body_bytes[64] = self.pro_table["wash_dry_course_three_dehydration_time"]
                body_bytes[65] = self.pro_table["wash_dry_course_three_dry"]
                body_bytes[66] = self.pro_table["wash_dry_course_three_temperature"]
                body_bytes[67] = self.pro_table["wash_dry_course_three_wash_rinse"] | self.pro_table["wash_dry_course_three_ufb"]
                body_bytes[68] = self.pro_table["wash_dry_course_three_base_program"]
            else:
                body_length = 47
                body_bytes = [0xFF] * body_length
                body_bytes[0] = 0x00
                body_bytes[1] = self.pro_table["command"]
                body_bytes[2] = self.pro_table["mode"]
                body_bytes[3] = self.pro_table["program"]
                body_bytes[4] = self.pro_table["reservationMin"]
                body_bytes[5] = self.pro_table["reservationHour"]
                body_bytes[6] = self.pro_table["timeSec"]
                body_bytes[7] = self.pro_table["timeMin"]
                body_bytes[8] = self.pro_table["timeHour"]
                body_bytes[9] = self.pro_table["washTime"]
                body_bytes[10] = self.pro_table["rinsePour"]
                body_bytes[11] = self.pro_table["dehydrationTime"]
                body_bytes[12] = self.pro_table["dry"]
                body_bytes[13] = self.pro_table["washRinse"] | self.pro_table["ufb"]
                body_bytes[14] = self.pro_table["temperature"]
                byte15 = 0x00
                if self.pro_table["lock"] != 0xFF:
                    byte15 |= self.pro_table["lock"]
                if self.pro_table["tubAutoClean"] != 0xFF:
                    byte15 |= self.pro_table["tubAutoClean"]
                if self.pro_table["buzzer"] != 0xFF:
                    byte15 |= self.pro_table["buzzer"]
                if self.pro_table["rinseMode"] != 0xFF:
                    byte15 |= self.pro_table["rinseMode"]
                if self.pro_table["lowNoise"] != 0xFF:
                    byte15 |= self.pro_table["lowNoise"]
                if self.pro_table["energySaving"] != 0xFF:
                    byte15 |= self.pro_table["energySaving"]
                if self.pro_table["hotWaterFifteen"] != 0xFF:
                    byte15 |= self.pro_table["hotWaterFifteen"]
                body_bytes[15] = byte15

                byte16 = 0x00
                if self.pro_table["dryFinishAdjust"] is not None:
                    byte16 |= self.pro_table["dryFinishAdjust"]
                if self.pro_table["spinRotateAdjust"] is not None:
                    byte16 |= (self.pro_table["spinRotateAdjust"] << 3)
                if self.pro_table["fungusProtect"] is not None:
                    byte16 |= self.pro_table["fungusProtect"]
                if self.pro_table["drainBubbleProtect"] is not None:
                    byte16 |= self.pro_table["drainBubbleProtect"]
                body_bytes[16] = byte16

                body_bytes[17] = self.pro_table["defaultDry"]

                byte38 = 0x00
                if self.pro_table["detergentSetting"] is not None:
                    byte38 |= (self.pro_table["detergentSetting"] << 7)
                if self.pro_table["detergentRemainExplanation"] is not None:
                    byte38 |= ((self.pro_table["detergentRemainExplanation"] << 4) & 0x70)
                body_bytes[38] = byte38

                byte39 = 0x00
                if self.pro_table["softnerSetting"] is not None:
                    byte39 |= (self.pro_table["softnerSetting"] << 7)
                if self.pro_table["softnerRemainExplanation"] is not None:
                    byte39 |= ((self.pro_table["softnerRemainExplanation"] << 4) & 0x70)
                body_bytes[39] = byte39

                body_bytes[40] = self.pro_table["detergentName"]
                body_bytes[41] = self.pro_table["softnerName"]
                body_bytes[42] = self.pro_table["detergentMeasure"]
                body_bytes[43] = self.pro_table["softnerMeasure"]
            msg_bytes = self.assemble_uart(body_bytes, 0x0002)
        elif query is not None:
            body_bytes = [0x00]
            msg_bytes = self.assemble_uart(body_bytes, 0x0003)

        info_m = [msg_bytes[i] for i in range(len(msg_bytes))]
        ret = self.table_to_string(info_m)
        ret = self.string_to_hexstring(ret)
        return ret

    def data_to_json(self, binData: str) -> str:
        bodyBytes = {}
        byteData = self.string_to_table(binData)
        self.dataType = byteData[15]
        self.subDataType = byteData[17]
        bodyBytes = self.extract_body_bytes(byteData)
        ret = self.updateGlobalPropertyValueByByte(bodyBytes)
        retTable = {}
        retTable["status"] = self.assembleJsonByGlobalProperty()
        ret = self.encode_table_to_json(retTable)
        return ret
