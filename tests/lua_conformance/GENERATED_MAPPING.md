# LUA <-> midealocal mapping

| device type | lua | midealocal | status | # lua files | evidence |
| --- | --- | --- | --- | --- | --- |
| a1 | lua/a1 | midealocal/devices/a1 | MATCHED | 7 | filename type token 'a1' == DeviceType byte 0xA1 |
| ac | lua/ac | midealocal/devices/ac | MATCHED | 38 | filename type token 'ac' == DeviceType byte 0xAC |
| b0 | lua/b0 | midealocal/devices/b0 | MATCHED | 3 | BYTE_DEVICE_TYPE == DeviceType.B0 (0xB0) |
| b1 | lua/b1 | midealocal/devices/b1 | MATCHED | 3 | BYTE_DEVICE_TYPE == DeviceType.B1 (0xB1) |
| b3 | lua/b3 | midealocal/devices/b3 | MATCHED | 3 | filename type token 'b3' == DeviceType byte 0xB3 |
| b4 | lua/b4 | midealocal/devices/b4 | MATCHED | 1 | BYTE_DEVICE_TYPE == DeviceType.B4 (0xB4) |
| b6 | lua/b6 | midealocal/devices/b6 | MATCHED | 5 | filename type token 'b6' == DeviceType byte 0xB6 |
| b8 | lua/b8 | midealocal/devices/b8 | MATCHED | 3 | BYTE_DEVICE_TYPE == DeviceType.B8 (0xB8) |
| bf | lua/bf | midealocal/devices/bf | MATCHED | 5 | BYTE_DEVICE_TYPE == DeviceType.BF (0xBF) |
| c3 | lua/c3 | midealocal/devices/c3 | MATCHED | 3 | filename type token 'c3' == DeviceType byte 0xC3 |
| ca | lua/ca | midealocal/devices/ca | MATCHED | 12 | filename type token 'ca' == DeviceType byte 0xCA |
| cc | lua/cc | midealocal/devices/cc | MATCHED | 2 | filename type token 'cc' == DeviceType byte 0xCC |
| cd | lua/cd | midealocal/devices/cd | MATCHED | 7 | BYTE_DEVICE_TYPE == DeviceType.CD (0xCD) |
| cf | lua/cf | midealocal/devices/cf | MATCHED | 1 | filename type token 'cf' == DeviceType byte 0xCF |
| da | lua/da | midealocal/devices/da | MATCHED | 1 | BYTE_DEVICE_TYPE == DeviceType.DA (0xDA) |
| db | lua/db | midealocal/devices/db | MATCHED | 9 | BYTE_DEVICE_TYPE == DeviceType.DB (0xDB) |
| dc | lua/dc | midealocal/devices/dc | MATCHED | 1 | filename type token 'dc' == DeviceType byte 0xDC |
| e1 | lua/e1 | midealocal/devices/e1 | MATCHED | 5 | filename type token 'e1' == DeviceType byte 0xE1 |
| e2 | lua/e2 | midealocal/devices/e2 | MATCHED | 3 | filename type token 'e2' == DeviceType byte 0xE2 |
| e3 | lua/e3 | midealocal/devices/e3 | MATCHED | 6 | filename type token 'e3' == DeviceType byte 0xE3 |
| e6 | lua/e6 | midealocal/devices/e6 | MATCHED | 3 | filename type token 'e6' == DeviceType byte 0xE6 |
| e8 | lua/e8 | midealocal/devices/e8 | MATCHED | 1 | filename type token 'e8' == DeviceType byte 0xE8 |
| ea | lua/ea | midealocal/devices/ea | MATCHED | 8 | BYTE_DEVICE_TYPE == DeviceType.EA (0xEA) |
| ec | lua/ec | midealocal/devices/ec | MATCHED | 1 | BYTE_DEVICE_TYPE == DeviceType.EC (0xEC) |
| ed | lua/ed | midealocal/devices/ed | MATCHED | 7 | filename type token 'ed' == DeviceType byte 0xED |
| fa | lua/fa | midealocal/devices/fa | MATCHED | 5 | filename type token 'fa' == DeviceType byte 0xFA |
| fb | lua/fb | midealocal/devices/fb | MATCHED | 2 | BYTE_DEVICE_TYPE == DeviceType.FB (0xFB) |
| fc | lua/fc | midealocal/devices/fc | MATCHED | 1 | BYTE_DEVICE_TYPE == DeviceType.FC (0xFC) |
| fd | lua/fd | midealocal/devices/fd | MATCHED | 2 | filename type token 'fd' == DeviceType byte 0xFD |
| x13 | lua/x13 | midealocal/devices/x13 | MATCHED | 3 | BYTE_DEVICE_TYPE == DeviceType.X13 (0x13) |
| x26 | lua/x26 | midealocal/devices/x26 | MATCHED | 1 | filename type token '26' == DeviceType byte 0x26 |
| x40 | lua/x40 | midealocal/devices/x40 | MATCHED | 1 | filename type token '40' == DeviceType byte 0x40 |
| ad | - | midealocal/devices/ad | UNMATCHED_NO_LUA | 0 | no lua/ directory with this name |
| c2 | - | midealocal/devices/c2 | UNMATCHED_NO_LUA | 0 | no lua/ directory with this name |
| ce | - | midealocal/devices/ce | UNMATCHED_NO_LUA | 0 | no lua/ directory with this name |
| x34 | - | midealocal/devices/x34 | UNMATCHED_NO_LUA | 0 | no lua/ directory with this name |
| b2 | lua/b2 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| b7 | lua/b7 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| c1 | lua/c1 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| d9 | lua/d9 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| e7 | lua/e7 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| e9 | lua/e9 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| eb | lua/eb | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| ef | lua/ef | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| f1 | lua/f1 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x10 | lua/x10 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x14 | lua/x14 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x17 | lua/x17 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x51 | lua/x51 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x70 | lua/x70 | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x9a | lua/x9a | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |
| x9b | lua/x9b | UNMATCHED | UNMATCHED_NO_PYTHON | 1 | no midealocal/devices package with this name |

## Summary

- MATCHED: 32
- UNMATCHED_NO_PYTHON: 16
- UNMATCHED_NO_LUA: 4
- lua files under mapped device types: 153
