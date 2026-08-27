# LUA protocol-conformance report

Verdicts: **MATCH** (agree) / **MISSING** (in Lua, not in midealocal) / **DIFFERENT** (both implement it, values disagree) / **UNKNOWN** (not auto-verifiable). A MISSING/DIFFERENT verdict is a *candidate* discrepancy, not a proven bug -- see README 'Interpreting failures'.

## Summary

| lua file | package | MATCH | MISSING | DIFFERENT | UNKNOWN |
| --- | --- | --- | --- | --- | --- |
| lua/a1/T_0000_A1_00000Q1A_2023112201.lua | a1 | 2 | 0 | 0 | 16 |
| lua/a1/T_0000_A1_00000Q1B_2023112201.lua | a1 | 2 | 0 | 0 | 16 |
| lua/a1/T_0000_A1_00000Q1D_2023112201.lua | a1 | 2 | 0 | 0 | 16 |
| lua/a1/T_0000_A1_3.lua | a1 | 10 | 1 | 1 | 9 |
| lua/a1/T_0000_A1_5.lua | a1 | 5 | 0 | 0 | 16 |
| lua/ac/T_0000_AC_00000Q11_2023072401.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q11_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q14_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q15_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q17_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q18_2023072401.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q19_2023072401.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q1B_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q1C_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_00000Q1F_2024013001.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_10693145_2024092401.lua | ac | 0 | 1 | 0 | 82 |
| lua/ac/T_0000_AC_22.lua | ac | 18 | 6 | 4 | 54 |
| lua/ac/T_0000_AC_22013005_2023010601.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22013133_2024010301.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22013279_2025030601.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22013303_2025092801.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22040023_2022111101.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22040047_2022040701.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22040055_2023110201.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22040079_2024090901.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_220F4047_2025091001.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22251637_2024011201.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22259015_2023072701.lua | ac | 0 | 1 | 0 | 82 |
| lua/ac/T_0000_AC_22270021_2020122401.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22270043_2021101401.lua | ac | 3 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_22396339_2022010702.lua | ac | 0 | 0 | 0 | 83 |
| lua/ac/T_0000_AC_23096613_2023102401.lua | ac | 0 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_23096653_2023121901.lua | ac | 0 | 1 | 0 | 82 |
| lua/ac/T_0000_AC_24.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0000_AC_24296529_2024022101.lua | ac | 0 | 1 | 0 | 82 |
| lua/ac/T_0000_AC_24296693_2024071901.lua | ac | 0 | 1 | 0 | 82 |
| lua/ac/T_0000_AC_75.lua | ac | 2 | 0 | 0 | 82 |
| lua/ac/T_0008_AC_24.lua | ac | 1 | 0 | 0 | 82 |
| lua/ac/T_0008_AC_26.lua | ac | 1 | 0 | 0 | 82 |
| lua/ac/T_0008_AC_28.lua | ac | 1 | 0 | 0 | 82 |
| lua/ac/T_0008_AC_29.lua | ac | 1 | 0 | 0 | 82 |
| lua/b0/T_0000_B0_0EM34A2E_6.lua | b0 | 4 | 0 | 0 | 25 |
| lua/b0/T_0000_B0_0TG025JG_2021070701.lua | b0 | 4 | 0 | 0 | 25 |
| lua/b0/T_0000_B0_6.lua | b0 | 37 | 2 | 8 | 8 |
| lua/b1/T_0000_B1_4.lua | b1 | 4 | 10 | 5 | 7 |
| lua/b3/T_0000_B3_0090Q15S_2022012701.lua | b3 | 0 | 0 | 0 | 54 |
| lua/b3/T_0000_B3_16.lua | b3 | 0 | 0 | 0 | 54 |
| lua/b3/T_0000_B3_7310032C_2023021701.lua | b3 | 0 | 0 | 0 | 54 |
| lua/b4/T_0000_B4_5.lua | b4 | 4 | 8 | 2 | 9 |
| lua/b6/T_0000_B6_07.lua | b6 | 0 | 0 | 0 | 9 |
| lua/b6/T_0000_B6_4.lua | b6 | 3 | 3 | 2 | 3 |
| lua/b6/T_0000_B6_5.lua | b6 | 0 | 0 | 0 | 9 |
| lua/b6/T_0000_B6_7300074R_2021070601.lua | b6 | 0 | 0 | 0 | 9 |
| lua/b6/T_0000_B6_73000J39_2021122001.lua | b6 | 0 | 0 | 0 | 9 |
| lua/b8/T_0000_B8_6.lua | b8 | 5 | 0 | 0 | 7 |
| lua/b8/T_0000_B8_7500001H_2023050601.lua | b8 | 2 | 0 | 0 | 5 |
| lua/b8/T_0000_B8_750004CE_2024011101.lua | b8 | 2 | 0 | 0 | 5 |
| lua/bf/T_0000_BF_700006AG_2023092801.lua | bf | 4 | 0 | 0 | 9 |
| lua/bf/T_0008_BF_2.lua | bf | 0 | 0 | 0 | 5 |
| lua/bf/T_0008_BF_3.lua | bf | 0 | 0 | 0 | 6 |
| lua/bf/T_0008_BF_4.lua | bf | 0 | 0 | 0 | 5 |
| lua/bf/T_0008_BF_5.lua | bf | 0 | 0 | 0 | 5 |
| lua/c3/T_0000_C3_17100003_2024011601.lua | c3 | 2 | 0 | 0 | 3 |
| lua/c3/T_0000_C3_171H120F_2023062601.lua | c3 | 0 | 0 | 0 | 3 |
| lua/ca/T_0000_CA_16.lua | ca | 1 | 0 | 0 | 64 |
| lua/ca/T_0000_CA_21.lua | ca | 1 | 0 | 0 | 64 |
| lua/ca/T_0000_CA_5.lua | ca | 12 | 64 | 0 | 49 |
| lua/ca/T_0008_CA_21.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_22.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_24.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_25.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_27.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_28.lua | ca | 0 | 0 | 0 | 4 |
| lua/ca/T_0008_CA_29.lua | ca | 0 | 0 | 0 | 4 |
| lua/cc/T_0000_CC_6.lua | cc | 5 | 0 | 0 | 27 |
| lua/cd/T_0000_CD_000K86A2_3.lua | cd | 5 | 0 | 0 | 44 |
| lua/cd/T_0000_CD_14.lua | cd | 3 | 0 | 0 | 45 |
| lua/cd/T_0000_CD_3.lua | cd | 22 | 32 | 2 | 27 |
| lua/cd/T_0000_CD_7.lua | cd | 5 | 0 | 0 | 44 |
| lua/cd/T_0000_CD_RSJ000CB_8.lua | cd | 5 | 0 | 0 | 44 |
| lua/cd/T_0000_CD_RSJRAC01_2023070401.lua | cd | 3 | 0 | 0 | 45 |
| lua/cf/T_0000_CF_4.lua | cf | 0 | 1 | 0 | 2 |
| lua/da/T_0000_DA_7.lua | da | 16 | 2 | 5 | 4 |
| lua/db/T_0000_DB_14.lua | db | 19 | 4 | 2 | 7 |
| lua/db/T_0000_DB_33.lua | db | 9 | 0 | 0 | 18 |
| lua/db/T_0000_DB_41.lua | db | 9 | 0 | 0 | 18 |
| lua/db/T_0008_DB_24.lua | db | 0 | 0 | 0 | 4 |
| lua/db/T_0008_DB_25.lua | db | 0 | 0 | 0 | 5 |
| lua/db/T_0008_DB_26.lua | db | 0 | 0 | 0 | 4 |
| lua/db/T_0008_DB_27.lua | db | 0 | 0 | 0 | 4 |
| lua/db/T_0008_DB_29.lua | db | 0 | 0 | 0 | 4 |
| lua/db/T_0008_DB_30.lua | db | 0 | 0 | 0 | 4 |
| lua/dc/T_0000_DC_5.lua | dc | 0 | 0 | 0 | 15 |
| lua/e1/T_0000_E1_22.lua | e1 | 0 | 0 | 0 | 35 |
| lua/e1/T_0000_E1_3.lua | e1 | 18 | 0 | 6 | 26 |
| lua/e1/T_0000_E1_5.lua | e1 | 0 | 0 | 0 | 35 |
| lua/e1/T_0000_E1_7600644C_2022031801.lua | e1 | 0 | 0 | 0 | 35 |
| lua/e1/T_0000_E1_760RX20S_2020091803.lua | e1 | 0 | 0 | 0 | 35 |
| lua/e2/T_0000_E2_24.lua | e2 | 0 | 0 | 0 | 44 |
| lua/e2/T_0000_E2_51021574_2022083001.lua | e2 | 0 | 0 | 0 | 43 |
| lua/e2/T_0000_E2_9.lua | e2 | 15 | 7 | 0 | 31 |
| lua/e3/T_0000_E3_1.lua | e3 | 0 | 0 | 0 | 10 |
| lua/e3/T_0000_E3_11.lua | e3 | 0 | 0 | 0 | 10 |
| lua/e3/T_0000_E3_511018BD_2023033101.lua | e3 | 0 | 0 | 0 | 10 |
| lua/e3/T_0000_E3_511018E4_2024040701.lua | e3 | 0 | 0 | 0 | 10 |
| lua/e3/T_0000_E3_511018HW_2025052801.lua | e3 | 0 | 0 | 0 | 10 |
| lua/e3/T_0000_E3_8.lua | e3 | 5 | 4 | 0 | 8 |
| lua/e6/T_0000_E6_2761011M_2021081901.lua | e6 | 0 | 0 | 0 | 15 |
| lua/e6/T_0000_E6_2761013B_2022082501.lua | e6 | 0 | 0 | 0 | 15 |
| lua/e6/T_0000_E6_9.lua | e6 | 0 | 0 | 0 | 15 |
| lua/e8/T_0000_E8_2.lua | e8 | 0 | 8 | 0 | 1 |
| lua/ea/T_0000_EA_15.lua | ea | 24 | 27 | 9 | 1 |
| lua/ea/T_0000_EA_61001599_2021012601.lua | ea | 4 | 0 | 0 | 25 |
| lua/ea/T_0008_EA_1.lua | ea | 0 | 0 | 0 | 4 |
| lua/ea/T_0008_EA_2.lua | ea | 0 | 0 | 0 | 4 |
| lua/ea/T_0008_EA_3.lua | ea | 0 | 0 | 0 | 4 |
| lua/ea/T_0008_EA_4.lua | ea | 0 | 0 | 0 | 4 |
| lua/ea/T_0008_EA_5.lua | ea | 0 | 0 | 0 | 4 |
| lua/ea/T_0008_EA_6.lua | ea | 0 | 0 | 0 | 4 |
| lua/ec/T_0000_EC_4.lua | ec | 3 | 0 | 0 | 14 |
| lua/ed/T_0000_ED_28.lua | ed | 0 | 0 | 0 | 24 |
| lua/ed/T_0000_ED_6.lua | ed | 6 | 8 | 3 | 13 |
| lua/ed/T_0000_ED_63100005_2023042701.lua | ed | 5 | 0 | 0 | 22 |
| lua/ed/T_0000_ED_63200860_2023041401.lua | ed | 5 | 0 | 0 | 22 |
| lua/ed/T_0000_ED_6320097A_2024011602.lua | ed | 6 | 0 | 0 | 22 |
| lua/ed/T_0000_ED_632009GC_2025090401.lua | ed | 5 | 0 | 0 | 22 |
| lua/ed/T_0000_ED_6321898A_2021091403.lua | ed | 6 | 0 | 0 | 22 |
| lua/fa/T_0000_FA_17.lua | fa | 0 | 0 | 0 | 11 |
| lua/fa/T_0000_FA_560000F3_2023011001.lua | fa | 0 | 0 | 0 | 11 |
| lua/fa/T_0000_FA_56011CB4_2023081801.lua | fa | 0 | 0 | 0 | 11 |
| lua/fa/T_0000_FA_56011CEC_2024072501.lua | fa | 0 | 0 | 0 | 11 |
| lua/fa/T_0000_FA_7.lua | fa | 5 | 21 | 0 | 5 |
| lua/fb/T_0000_FB_3.lua | fb | 14 | 8 | 5 | 3 |
| lua/fb/T_0000_FB_5706672H_2021072201.lua | fb | 0 | 0 | 0 | 12 |
| lua/fc/T_0000_FC_6.lua | fc | 12 | 6 | 1 | 11 |
| lua/fd/T_0000_FD_202Z3119_2024110101.lua | fd | 2 | 0 | 0 | 11 |
| lua/fd/T_0000_FD_6.lua | fd | 9 | 1 | 1 | 5 |
| lua/x13/T_0000_13_2.lua | x13 | 4 | 28 | 0 | 2 |
| lua/x13/T_0000_13_79010863_2024022102.lua | x13 | 4 | 8 | 0 | 3 |
| lua/x13/T_0000_13_M0200002_2025042802.lua | x13 | 4 | 0 | 0 | 3 |
| lua/x26/T_0000_26_M0100032_2023091101.lua | x26 | 3 | 1 | 0 | 3 |
| lua/x40/T_0000_40_M0100002_2024011701.lua | x40 | 3 | 1 | 0 | 9 |
| **total** | | 451 | 266 | 56 | 4606 |

## DIFFERENT

### a1: fan_speed

```
[DIFFERENT] decode_field: fan_speed
    field parsed from a different offset/mask/shift
    lua source : lua/a1/T_0000_A1_3.lua:94
    lua        : byte[3] & 0xFF >> 0
    midealocal : byte[3] & 0x7F >> 0  (body[3] & 127)
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ac: swing_lr

```
[DIFFERENT] decode_field: swing_lr
    field parsed from a different offset/mask/shift
    lua source : lua/ac/T_0000_AC_22.lua:261
    lua        : byte[7] & 0x03 >> 0
    midealocal : byte[20] & 0x80 >> 0  (body[20] & 128 if len(body) >= SWING_LR_MIN_LENGTH else 0)
    example    : raw byte 0x24 -> lua 0, midealocal 0
```

### ac: prevent_cold

```
[DIFFERENT] decode_field: prevent_cold
    field parsed from a different offset/mask/shift
    lua source : lua/ac/T_0000_AC_22.lua:273
    lua        : byte[10] & 0x08 >> 3
    midealocal : byte[10] & 0x20 >> 5  ((body[10] & 32) >> 5)
    example    : raw byte 0x24 -> lua 0, midealocal 1
```

### ac: indoor_temperature

```
[DIFFERENT] decode_field: indoor_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ac/T_0000_AC_22.lua:277
    lua        : byte[13] & 0xFF >> 0  ((messageBytes[13] - 50) / 2)
    midealocal : byte[11] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ac: outdoor_temperature

```
[DIFFERENT] decode_field: outdoor_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ac/T_0000_AC_22.lua:280
    lua        : byte[14] & 0xFF >> 0  ((messageBytes[14] - 50) / 2)
    midealocal : byte[12] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### b0: mode[0x06]

```
[DIFFERENT] enum: mode[0x06]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:38
    lua        : 0x06 -> 'hot_steam'
    midealocal : 0x06 -> 'host_steam'
```

### b0: mode[0x43]

```
[DIFFERENT] enum: mode[0x43]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:38
    lua        : 0x43 -> 'fast_baking'
    midealocal : 0x43 -> 'baking'
```

### b0: status[0x02]

```
[DIFFERENT] enum: status[0x02]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:63
    lua        : 0x02 -> 'work'
    midealocal : 0x02 -> 'idle'
```

### b0: status[0x03]

```
[DIFFERENT] enum: status[0x03]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:63
    lua        : 0x03 -> 'pause'
    midealocal : 0x03 -> 'working'
```

### b0: status[0x04]

```
[DIFFERENT] enum: status[0x04]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:63
    lua        : 0x04 -> 'end'
    midealocal : 0x04 -> 'finished'
```

### b0: status[0x09]

```
[DIFFERENT] enum: status[0x09]
    same protocol value, different logical name
    lua source : lua/b0/T_0000_B0_6.lua:63
    lua        : 0x09 -> 'three_sec'
    midealocal : 0x09 -> 'three'
```

### b0: status

```
[DIFFERENT] decode_field: status
    field parsed from a different offset/mask/shift
    lua source : lua/b0/T_0000_B0_6.lua:201
    lua        : byte[0] & 0x7F >> 0
    midealocal : byte[1] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### b0: mode

```
[DIFFERENT] decode_field: mode
    field parsed from a different offset/mask/shift
    lua source : lua/b0/T_0000_B0_6.lua:207
    lua        : byte[1] & 0xFF >> 0
    midealocal : byte[9] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### b1: status[0x01]

```
[DIFFERENT] enum: status[0x01]
    same protocol value, different logical name
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0x01 -> 'cancel'
    midealocal : 0x01 -> 'standby'
```

### b1: status[0x02]

```
[DIFFERENT] enum: status[0x02]
    same protocol value, different logical name
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0x02 -> 'work'
    midealocal : 0x02 -> 'idle'
```

### b1: status[0x03]

```
[DIFFERENT] enum: status[0x03]
    same protocol value, different logical name
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0x03 -> 'pause'
    midealocal : 0x03 -> 'working'
```

### b1: status[0x04]

```
[DIFFERENT] enum: status[0x04]
    same protocol value, different logical name
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0x04 -> 'end'
    midealocal : 0x04 -> 'finished'
```

### b1: status[0x06]

```
[DIFFERENT] enum: status[0x06]
    same protocol value, different logical name
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0x06 -> 'appointment'
    midealocal : 0x06 -> 'paused'
```

### b4: status[0x02]

```
[DIFFERENT] enum: status[0x02]
    same protocol value, different logical name
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x02 -> 'work'
    midealocal : 0x02 -> 'idle'
```

### b4: status[0x05]

```
[DIFFERENT] enum: status[0x05]
    same protocol value, different logical name
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x05 -> 'lock_on'
    midealocal : 0x05 -> 'delay'
```

### b6: power

```
[DIFFERENT] decode_field: power
    field parsed from a different offset/mask/shift
    lua source : lua/b6/T_0000_B6_4.lua:54
    lua        : byte[3] & 0x0F >> 0
    midealocal : byte[3] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 4, midealocal 36
```

### b6: light

```
[DIFFERENT] decode_field: light
    field parsed from a different offset/mask/shift
    lua source : lua/b6/T_0000_B6_4.lua:55
    lua        : byte[4] & 0x80 >> 0
    midealocal : byte[2] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 0, midealocal 36
```

### cd: power

```
[DIFFERENT] decode_field: power
    field parsed from a different offset/mask/shift
    lua source : lua/cd/T_0000_CD_3.lua:207
    lua        : byte[2] & 0xFF >> 0
    midealocal : byte[2] & 0x01 >> 0  (body[2] & 1 > 0)
    example    : raw byte 0x24 -> lua 36, midealocal 0
```

### cd: water_pump

```
[DIFFERENT] decode_field: water_pump
    field parsed from a different offset/mask/shift
    lua source : lua/cd/T_0000_CD_3.lua:213
    lua        : byte[8] & 0x01 >> 0
    midealocal : byte[27] & 0x04 >> 0  (body[27] & 4 > 0)
    example    : raw byte 0x24 -> lua 0, midealocal 4
```

### da: rinse_level

```
[DIFFERENT] decode_field: rinse_level
    field parsed from a different offset/mask/shift
    lua source : lua/da/T_0000_DA_7.lua:300
    lua        : byte[5] & 0xFF >> 4
    midealocal : byte[5] & 0xF0 >> 4  ((body[5] & 240) >> 4)
    example    : raw byte 0x24 -> lua 2, midealocal 2
```

### da: dehydration_speed

```
[DIFFERENT] decode_field: dehydration_speed
    field parsed from a different offset/mask/shift
    lua source : lua/da/T_0000_DA_7.lua:302
    lua        : byte[6] & 0xFF >> 4
    midealocal : byte[6] & 0xF0 >> 4  ((body[6] & 240) >> 4)
    example    : raw byte 0x24 -> lua 2, midealocal 2
```

### da: dehydration_time

```
[DIFFERENT] decode_field: dehydration_time
    field parsed from a different offset/mask/shift
    lua source : lua/da/T_0000_DA_7.lua:315
    lua        : byte[10] & 0xFF >> 4
    midealocal : byte[10] & 0xF0 >> 4  ((body[10] & 240) >> 4)
    example    : raw byte 0x24 -> lua 2, midealocal 2
```

### da: program

```
[DIFFERENT] decode_field: program
    field parsed from a different offset/mask/shift
    lua source : lua/da/T_0000_DA_7.lua:323
    lua        : byte[3] & 0xFF >> 0
    midealocal : byte[4] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### da: error_code

```
[DIFFERENT] decode_field: error_code
    field parsed from a different offset/mask/shift
    lua source : lua/da/T_0000_DA_7.lua:324
    lua        : byte[6] & 0xFF >> 0
    midealocal : byte[24] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### db: mode

```
[DIFFERENT] decode_field: mode
    field parsed from a different offset/mask/shift
    lua source : lua/db/T_0000_DB_14.lua:402
    lua        : byte[2] & 0xFF >> 0
    midealocal : byte[3] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### db: program

```
[DIFFERENT] decode_field: program
    field parsed from a different offset/mask/shift
    lua source : lua/db/T_0000_DB_14.lua:403
    lua        : byte[3] & 0xFF >> 0
    midealocal : byte[4] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### e1: mode[0x00]

```
[DIFFERENT] enum: mode[0x00]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:23
    lua        : 0x00 -> 'neutral_gear'
    midealocal : 0x00 -> 'none'
```

### e1: mode[0x09]

```
[DIFFERENT] enum: mode[0x09]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:23
    lua        : 0x09 -> 'self_define'
    midealocal : 0x09 -> '90min'
```

### e1: status[0x00]

```
[DIFFERENT] enum: status[0x00]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:41
    lua        : 0x00 -> 'power_off'
    midealocal : 0x00 -> 'off'
```

### e1: status[0x02]

```
[DIFFERENT] enum: status[0x02]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:41
    lua        : 0x02 -> 'order'
    midealocal : 0x02 -> 'delay'
```

### e1: status[0x03]

```
[DIFFERENT] enum: status[0x03]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:41
    lua        : 0x03 -> 'work'
    midealocal : 0x03 -> 'running'
```

### e1: status[0x04]

```
[DIFFERENT] enum: status[0x04]
    same protocol value, different logical name
    lua source : lua/e1/T_0000_E1_3.lua:41
    lua        : 0x04 -> 'cancel_order'
    midealocal : 0x04 -> 'error'
```

### ea: mode

```
[DIFFERENT] decode_field: mode
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:443
    lua        : byte[4] & 0xFF >> 0  (messageBytes[4] + bit.lshift(messageBytes[5], 8))
    midealocal : byte[7] & 0xFF >> 0  (body[7] + (body[8] << 8))
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: top_temperature

```
[DIFFERENT] decode_field: top_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:456
    lua        : byte[20] & 0xFF >> 0
    midealocal : byte[60] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: bottom_temperature

```
[DIFFERENT] decode_field: bottom_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:457
    lua        : byte[21] & 0xFF >> 0
    midealocal : byte[61] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: mode

```
[DIFFERENT] decode_field: mode
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:495
    lua        : byte[6] & 0xFF >> 0  (messageBytes[6] + bit.lshift(messageBytes[7], 8))
    midealocal : byte[7] & 0xFF >> 0  (body[7] + (body[8] << 8))
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: top_temperature

```
[DIFFERENT] decode_field: top_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:505
    lua        : byte[18] & 0xFF >> 0
    midealocal : byte[60] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: bottom_temperature

```
[DIFFERENT] decode_field: bottom_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:506
    lua        : byte[19] & 0xFF >> 0
    midealocal : byte[61] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: mode

```
[DIFFERENT] decode_field: mode
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:517
    lua        : byte[58] & 0xFF >> 0  (messageBytes[58] + bit.lshift(messageBytes[59], 8))
    midealocal : byte[7] & 0xFF >> 0  (body[7] + (body[8] << 8))
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: top_temperature

```
[DIFFERENT] decode_field: top_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:529
    lua        : byte[21] & 0xFF >> 0
    midealocal : byte[60] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ea: bottom_temperature

```
[DIFFERENT] decode_field: bottom_temperature
    field parsed from a different offset/mask/shift
    lua source : lua/ea/T_0000_EA_15.lua:530
    lua        : byte[20] & 0xFF >> 0
    midealocal : byte[61] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ed: life1

```
[DIFFERENT] decode_field: life1
    field parsed from a different offset/mask/shift
    lua source : lua/ed/T_0000_ED_6.lua:113
    lua        : byte[16] & 0xFF >> 0
    midealocal : byte[22] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ed: life2

```
[DIFFERENT] decode_field: life2
    field parsed from a different offset/mask/shift
    lua source : lua/ed/T_0000_ED_6.lua:114
    lua        : byte[17] & 0xFF >> 0
    midealocal : byte[23] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### ed: life3

```
[DIFFERENT] decode_field: life3
    field parsed from a different offset/mask/shift
    lua source : lua/ed/T_0000_ED_6.lua:115
    lua        : byte[18] & 0xFF >> 0
    midealocal : byte[24] & 0xFF >> 0
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

### fb: mode[0x01]

```
[DIFFERENT] enum: mode[0x01]
    same protocol value, different logical name
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x01 -> 'intelligent'
    midealocal : 0x01 -> 'auto'
```

### fb: mode[0x02]

```
[DIFFERENT] enum: mode[0x02]
    same protocol value, different logical name
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x02 -> 'efficient'
    midealocal : 0x02 -> 'eco'
```

### fb: mode[0x08]

```
[DIFFERENT] enum: mode[0x08]
    same protocol value, different logical name
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x08 -> 'fast_hot'
    midealocal : 0x08 -> 'fast_heating'
```

### fb: mode[0x10]

```
[DIFFERENT] enum: mode[0x10]
    same protocol value, different logical name
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x10 -> 'humidity_close'
    midealocal : 0x10 -> 'standby'
```

### fb: power

```
[DIFFERENT] decode_field: power
    field parsed from a different offset/mask/shift
    lua source : lua/fb/T_0000_FB_3.lua:157
    lua        : byte[0] & 0xFF >> 0
    midealocal : byte[0] & 0x01 >> 0  (body[0] & 1 not in [0, 2])
    example    : raw byte 0x24 -> lua 36, midealocal 0
```

### fc: anion

```
[DIFFERENT] decode_field: anion
    field parsed from a different offset/mask/shift
    lua source : lua/fc/T_0000_FC_6.lua:131
    lua        : byte[9] & 0x40 >> 0
    midealocal : byte[10] & 0x20 >> 0  (body[10] & 32 > 0 if len(body) > ANION_NOTIFY_BYTE else False)
    example    : raw byte 0x24 -> lua 0, midealocal 32
```

### fd: fan_speed

```
[DIFFERENT] decode_field: fan_speed
    field parsed from a different offset/mask/shift
    lua source : lua/fd/T_0000_FD_6.lua:63
    lua        : byte[3] & 0xFF >> 0
    midealocal : byte[3] & 0x7F >> 0  (body[3] & 127)
    example    : raw byte 0x24 -> lua 36, midealocal 36
```

## MISSING

### a1: tank_status

```
[MISSING] decode_field: tank_status
    Lua reads 'tankStatusValue' from byte[10] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/a1/T_0000_A1_3.lua:97
    lua        : tankStatusValue = byte[10] & 0xFF >> 0
```

### ac: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/ac/T_0000_AC_10693145_2024092401.lua:5338
```

### ac: small_temperature

```
[MISSING] decode_field: small_temperature
    Lua reads 'smallTemperature' from byte[2] (mask 0x10, shift 4); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:232
    lua        : smallTemperature = byte[2] & 0x10 >> 4
```

### ac: close_hour

```
[MISSING] decode_field: close_hour
    Lua reads 'closeHour' from byte[5] (mask 0x7F, shift 2); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:247
    lua        : closeHour = byte[5] & 0x7F >> 2
```

### ac: close_step_mintues

```
[MISSING] decode_field: close_step_mintues
    Lua reads 'closeStepMintues' from byte[5] (mask 0x03, shift 0); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:248
    lua        : closeStepMintues = byte[5] & 0x03 >> 0
```

### ac: open_hour

```
[MISSING] decode_field: open_hour
    Lua reads 'openHour' from byte[4] (mask 0x7F, shift 2); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:251
    lua        : openHour = byte[4] & 0x7F >> 2
```

### ac: open_step_mintues

```
[MISSING] decode_field: open_step_mintues
    Lua reads 'openStepMintues' from byte[4] (mask 0x03, shift 0); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:252
    lua        : openStepMintues = byte[4] & 0x03 >> 0
```

### ac: ptc

```
[MISSING] decode_field: ptc
    Lua reads 'PTCValue' from byte[9] (mask 0x18, shift 0); midealocal parses nothing there
    lua source : lua/ac/T_0000_AC_22.lua:257
    lua        : PTCValue = byte[9] & 0x18 >> 0
```

### ac: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/ac/T_0000_AC_22259015_2023072701.lua:2434
```

### ac: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/ac/T_0000_AC_23096653_2023121901.lua:3021
```

### ac: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/ac/T_0000_AC_24296529_2024022101.lua:3171
```

### ac: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/ac/T_0000_AC_24296693_2024071901.lua:3473
```

### b0: mode[0x02]

```
[MISSING] enum: mode[0x02]
    Lua maps 0x02 -> 'baking'; midealocal has no entry for that value
    lua source : lua/b0/T_0000_B0_6.lua:38
    lua        : 0x02 -> 'baking'
```

### b0: second

```
[MISSING] decode_field: second
    Lua reads 'second' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b0/T_0000_B0_6.lua:209
    lua        : second = byte[3] & 0xFF >> 0
```

### b1: status[0xFF]

```
[MISSING] enum: status[0xFF]
    Lua maps 0xFF -> 'none'; midealocal has no entry for that value
    lua source : lua/b1/T_0000_B1_4.lua:30
    lua        : 0xFF -> 'none'
```

### b1: workstatus

```
[MISSING] decode_field: workstatus
    Lua reads 'workstatus' from byte[0] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:143
    lua        : workstatus = byte[0] & 0xFF >> 0
```

### b1: hour

```
[MISSING] decode_field: hour
    Lua reads 'hour' from byte[2] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:145
    lua        : hour = byte[2] & 0xFF >> 0
```

### b1: minutes

```
[MISSING] decode_field: minutes
    Lua reads 'minutes' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:146
    lua        : minutes = byte[3] & 0xFF >> 0
```

### b1: cur_temp

```
[MISSING] decode_field: cur_temp
    Lua reads 'curTemp' from byte[4] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:148
    lua        : curTemp = byte[4] & 0xFF >> 0  (messageBytes[4] + 256)
```

### b1: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[5] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:152
    lua        : errorCode = byte[5] & 0xFF >> 0
```

### b1: temperature

```
[MISSING] decode_field: temperature
    Lua reads 'temperature' from byte[8] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:154
    lua        : temperature = byte[8] & 0xFF >> 0  ((messageBytes[8] + 256))
```

### b1: lock

```
[MISSING] decode_field: lock
    Lua reads 'lock' from byte[16] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b1/T_0000_B1_4.lua:158
    lua        : lock = byte[16] & 0xFF >> 0
```

### b1: body_type 0x22

```
[MISSING] command: body_type 0x22
    Lua builds a request with body[0]=0x22 (trigger 'power'); no midealocal Message* emits that body type
    lua source : lua/b1/T_0000_B1_4.lua:323
```

### b1: body_type 0x31

```
[MISSING] command: body_type 0x31
    Lua builds a request with body[0]=0x31 (trigger 'furnace_light'); no midealocal Message* emits that body type
    lua source : lua/b1/T_0000_B1_4.lua:323
```

### b4: status[0x07]

```
[MISSING] enum: status[0x07]
    Lua maps 0x07 -> 'save_power'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x07 -> 'save_power'
```

### b4: status[0x08]

```
[MISSING] enum: status[0x08]
    Lua maps 0x08 -> 'preheating'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x08 -> 'preheating'
```

### b4: status[0x0A]

```
[MISSING] enum: status[0x0A]
    Lua maps 0x0A -> 'lock_off'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x0A -> 'lock_off'
```

### b4: status[0x11]

```
[MISSING] enum: status[0x11]
    Lua maps 0x11 -> 'finish'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x11 -> 'finish'
```

### b4: status[0x66]

```
[MISSING] enum: status[0x66]
    Lua maps 0x66 -> 'recipes_finish'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x66 -> 'recipes_finish'
```

### b4: status[0x88]

```
[MISSING] enum: status[0x88]
    Lua maps 0x88 -> 'preheat_finish'; midealocal has no entry for that value
    lua source : lua/b4/T_0000_B4_5.lua:36
    lua        : 0x88 -> 'preheat_finish'
```

### b4: body_type 0x22

```
[MISSING] command: body_type 0x22
    Lua builds a request with body[0]=0x22 (trigger 'work_status'); no midealocal Message* emits that body type
    lua source : lua/b4/T_0000_B4_5.lua:272
```

### b4: body_type 0x04

```
[MISSING] command: body_type 0x04
    Lua builds a request with body[0]=0x04 (trigger 'lock'); no midealocal Message* emits that body type
    lua source : lua/b4/T_0000_B4_5.lua:272
```

### b6: intelligent

```
[MISSING] decode_field: intelligent
    Lua reads 'intelligent' from byte[0] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b6/T_0000_B6_4.lua:53
    lua        : intelligent = byte[0] & 0xFF >> 0
```

### b6: gear

```
[MISSING] decode_field: gear
    Lua reads 'gear' from byte[7] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b6/T_0000_B6_4.lua:57
    lua        : gear = byte[7] & 0xFF >> 0
```

### b6: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorcode' from byte[8] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/b6/T_0000_B6_4.lua:58
    lua        : errorcode = byte[8] & 0xFF >> 0
```

### ca: moisturize_mode

```
[MISSING] decode_field: moisturize_mode
    Lua reads 'moisturizeMode' from byte[1] (mask 0x20, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:308
    lua        : moisturizeMode = byte[1] & 0x20 >> 0
```

### ca: preservation_mode

```
[MISSING] decode_field: preservation_mode
    Lua reads 'preservationMode' from byte[1] (mask 0x40, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:309
    lua        : preservationMode = byte[1] & 0x40 >> 0
```

### ca: acme_freezing_mode

```
[MISSING] decode_field: acme_freezing_mode
    Lua reads 'acmeFreezingMode' from byte[1] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:310
    lua        : acmeFreezingMode = byte[1] & 0x80 >> 0
```

### ca: refrigeration_temperature

```
[MISSING] decode_field: refrigeration_temperature
    Lua reads 'refrigerationTemperature' from byte[2] (mask 0x0F, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:311
    lua        : refrigerationTemperature = byte[2] & 0x0F >> 0
```

### ca: freezing_temperature

```
[MISSING] decode_field: freezing_temperature
    Lua reads 'freezingTemperature' from byte[2] (mask 0xF0, shift 4); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:312
    lua        : freezingTemperature = byte[2] & 0xF0 >> 4
```

### ca: l_variable_temperature

```
[MISSING] decode_field: l_variable_temperature
    Lua reads 'lVariableTemperature' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:313
    lua        : lVariableTemperature = byte[3] & 0xFF >> 0
```

### ca: r_variable_temperature

```
[MISSING] decode_field: r_variable_temperature
    Lua reads 'rVariableTemperature' from byte[4] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:314
    lua        : rVariableTemperature = byte[4] & 0xFF >> 0
```

### ca: variable_mode

```
[MISSING] decode_field: variable_mode
    Lua reads 'variableModeValue' from byte[5] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:315
    lua        : variableModeValue = byte[5] & 0xFF >> 0
```

### ca: refrigeration_power

```
[MISSING] decode_field: refrigeration_power
    Lua reads 'refrigerationPowerValue' from byte[6] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:316
    lua        : refrigerationPowerValue = byte[6] & 0x01 >> 0
```

### ca: l_variable_power

```
[MISSING] decode_field: l_variable_power
    Lua reads 'lVariablePowerValue' from byte[6] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:317
    lua        : lVariablePowerValue = byte[6] & 0x04 >> 0
```

### ca: r_variable_power

```
[MISSING] decode_field: r_variable_power
    Lua reads 'rVariablePowerValue' from byte[6] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:318
    lua        : rVariablePowerValue = byte[6] & 0x08 >> 0
```

### ca: freezing_power

```
[MISSING] decode_field: freezing_power
    Lua reads 'freezingPowerValue' from byte[6] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:319
    lua        : freezingPowerValue = byte[6] & 0x10 >> 0
```

### ca: all_refrigeration_power

```
[MISSING] decode_field: all_refrigeration_power
    Lua reads 'allRefrigerationPower' from byte[6] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:320
    lua        : allRefrigerationPower = byte[6] & 0x80 >> 0
```

### ca: remove_dew

```
[MISSING] decode_field: remove_dew
    Lua reads 'removeDew' from byte[7] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:321
    lua        : removeDew = byte[7] & 0x01 >> 0
```

### ca: humidify

```
[MISSING] decode_field: humidify
    Lua reads 'humidify' from byte[7] (mask 0x02, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:322
    lua        : humidify = byte[7] & 0x02 >> 0
```

### ca: unfreeze

```
[MISSING] decode_field: unfreeze
    Lua reads 'unfreeze' from byte[7] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:323
    lua        : unfreeze = byte[7] & 0x04 >> 0
```

### ca: temperature_unit

```
[MISSING] decode_field: temperature_unit
    Lua reads 'temperatureUnit' from byte[7] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:324
    lua        : temperatureUnit = byte[7] & 0x08 >> 0
```

### ca: floodlight

```
[MISSING] decode_field: floodlight
    Lua reads 'floodlight' from byte[7] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:325
    lua        : floodlight = byte[7] & 0x10 >> 0
```

### ca: function_switch

```
[MISSING] decode_field: function_switch
    Lua reads 'functionSwitch' from byte[7] (mask 0xC0, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:326
    lua        : functionSwitch = byte[7] & 0xC0 >> 0
```

### ca: radar_mode

```
[MISSING] decode_field: radar_mode
    Lua reads 'radarMode' from byte[8] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:327
    lua        : radarMode = byte[8] & 0x01 >> 0
```

### ca: milk_mode

```
[MISSING] decode_field: milk_mode
    Lua reads 'milkMode' from byte[8] (mask 0x02, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:328
    lua        : milkMode = byte[8] & 0x02 >> 0
```

### ca: iced_mode

```
[MISSING] decode_field: iced_mode
    Lua reads 'icedMode' from byte[8] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:329
    lua        : icedMode = byte[8] & 0x04 >> 0
```

### ca: plasma_aseptic_mode

```
[MISSING] decode_field: plasma_aseptic_mode
    Lua reads 'plasmaAsepticMode' from byte[8] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:330
    lua        : plasmaAsepticMode = byte[8] & 0x08 >> 0
```

### ca: acquire_icea_mode

```
[MISSING] decode_field: acquire_icea_mode
    Lua reads 'acquireIceaMode' from byte[8] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:331
    lua        : acquireIceaMode = byte[8] & 0x10 >> 0
```

### ca: brash_icea_mode

```
[MISSING] decode_field: brash_icea_mode
    Lua reads 'brashIceaMode' from byte[8] (mask 0x20, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:332
    lua        : brashIceaMode = byte[8] & 0x20 >> 0
```

### ca: acquire_water_mode

```
[MISSING] decode_field: acquire_water_mode
    Lua reads 'acquireWaterMode' from byte[8] (mask 0x40, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:333
    lua        : acquireWaterMode = byte[8] & 0x40 >> 0
```

### ca: ice_machine_power

```
[MISSING] decode_field: ice_machine_power
    Lua reads 'iceMachinePower' from byte[8] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:334
    lua        : iceMachinePower = byte[8] & 0x80 >> 0
```

### ca: freezing_fahrenheit

```
[MISSING] decode_field: freezing_fahrenheit
    Lua reads 'freezingFahrenheit' from byte[9] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:335
    lua        : freezingFahrenheit = byte[9] & 0xFF >> 0
```

### ca: refrigeration_fahrenheit

```
[MISSING] decode_field: refrigeration_fahrenheit
    Lua reads 'refrigerationFahrenheit' from byte[10] (mask 0xFC, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:336
    lua        : refrigerationFahrenheit = byte[10] & 0xFC >> 0
```

### ca: leach_expire_day

```
[MISSING] decode_field: leach_expire_day
    Lua reads 'leachExpireDay' from byte[11] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:337
    lua        : leachExpireDay = byte[11] & 0xFF >> 0
```

### ca: power_consumption_low

```
[MISSING] decode_field: power_consumption_low
    Lua reads 'powerConsumptionLow' from byte[12] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:338
    lua        : powerConsumptionLow = byte[12] & 0xFF >> 0
```

### ca: power_consumption_high

```
[MISSING] decode_field: power_consumption_high
    Lua reads 'powerConsumptionHigh' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:339
    lua        : powerConsumptionHigh = byte[13] & 0xFF >> 0
```

### ca: motor_reset_status

```
[MISSING] decode_field: motor_reset_status
    Lua reads 'motorResetStatus' from byte[14] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:340
    lua        : motorResetStatus = byte[14] & 0x01 >> 0
```

### ca: motor_deicing_status

```
[MISSING] decode_field: motor_deicing_status
    Lua reads 'motorDeicingStatus' from byte[14] (mask 0x02, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:341
    lua        : motorDeicingStatus = byte[14] & 0x02 >> 0
```

### ca: ice_machine_water_status

```
[MISSING] decode_field: ice_machine_water_status
    Lua reads 'iceMachineWaterStatus' from byte[14] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:342
    lua        : iceMachineWaterStatus = byte[14] & 0x04 >> 0
```

### ca: all_icea_status

```
[MISSING] decode_field: all_icea_status
    Lua reads 'allIceaStatus' from byte[14] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:343
    lua        : allIceaStatus = byte[14] & 0x08 >> 0
```

### ca: human_induction

```
[MISSING] decode_field: human_induction
    Lua reads 'humanInduction' from byte[14] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:344
    lua        : humanInduction = byte[14] & 0x10 >> 0
```

### ca: refrigeration_door_power

```
[MISSING] decode_field: refrigeration_door_power
    Lua reads 'refrigerationDoorPower' from byte[15] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:345
    lua        : refrigerationDoorPower = byte[15] & 0x01 >> 0
```

### ca: freezing_door_power

```
[MISSING] decode_field: freezing_door_power
    Lua reads 'freezingDoorPower' from byte[15] (mask 0x02, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:346
    lua        : freezingDoorPower = byte[15] & 0x02 >> 0
```

### ca: variable_door_power

```
[MISSING] decode_field: variable_door_power
    Lua reads 'variableDoorPower' from byte[15] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:347
    lua        : variableDoorPower = byte[15] & 0x10 >> 0
```

### ca: bar_door_power

```
[MISSING] decode_field: bar_door_power
    Lua reads 'barDoorPower' from byte[15] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:348
    lua        : barDoorPower = byte[15] & 0x04 >> 0
```

### ca: ice_mouth_power

```
[MISSING] decode_field: ice_mouth_power
    Lua reads 'iceMouthPower' from byte[15] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:349
    lua        : iceMouthPower = byte[15] & 0x08 >> 0
```

### ca: is_error

```
[MISSING] decode_field: is_error
    Lua reads 'isError' from byte[16] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:350
    lua        : isError = byte[16] & 0x01 >> 0
```

### ca: interval_room_temperature_level

```
[MISSING] decode_field: interval_room_temperature_level
    Lua reads 'intervalRoomTemperatureLevel' from byte[16] (mask 0xFE, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:351
    lua        : intervalRoomTemperatureLevel = byte[16] & 0xFE >> 0
```

### ca: refrigeration_real_temperature

```
[MISSING] decode_field: refrigeration_real_temperature
    Lua reads 'refrigerationRealTemperature' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:352
    lua        : refrigerationRealTemperature = byte[17] & 0xFF >> 0
```

### ca: freezing_real_temperature

```
[MISSING] decode_field: freezing_real_temperature
    Lua reads 'freezingRealTemperature' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:353
    lua        : freezingRealTemperature = byte[18] & 0xFF >> 0
```

### ca: l_variable_real_temperature

```
[MISSING] decode_field: l_variable_real_temperature
    Lua reads 'lVariableRealTemperature' from byte[19] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:354
    lua        : lVariableRealTemperature = byte[19] & 0xFF >> 0
```

### ca: r_variable_real_temperature

```
[MISSING] decode_field: r_variable_real_temperature
    Lua reads 'rVariableRealTemperature' from byte[20] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:355
    lua        : rVariableRealTemperature = byte[20] & 0xFF >> 0
```

### ca: fast_cold_minute_low

```
[MISSING] decode_field: fast_cold_minute_low
    Lua reads 'fastColdMinuteLow' from byte[21] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:356
    lua        : fastColdMinuteLow = byte[21] & 0xFF >> 0
```

### ca: fast_cold_minute_high

```
[MISSING] decode_field: fast_cold_minute_high
    Lua reads 'fastColdMinuteHigh' from byte[22] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:357
    lua        : fastColdMinuteHigh = byte[22] & 0xFF >> 0
```

### ca: fast_freeze_minute_low

```
[MISSING] decode_field: fast_freeze_minute_low
    Lua reads 'fastFreezeMinuteLow' from byte[23] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:358
    lua        : fastFreezeMinuteLow = byte[23] & 0xFF >> 0
```

### ca: fast_freeze_minute_high

```
[MISSING] decode_field: fast_freeze_minute_high
    Lua reads 'fastFreezeMinuteHigh' from byte[24] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:359
    lua        : fastFreezeMinuteHigh = byte[24] & 0xFF >> 0
```

### ca: food_site

```
[MISSING] decode_field: food_site
    Lua reads 'foodSite' from byte[25] (mask 0x0F, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:361
    lua        : foodSite = byte[25] & 0x0F >> 0
```

### ca: beef

```
[MISSING] decode_field: beef
    Lua reads 'beef' from byte[25] (mask 0x40, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:362
    lua        : beef = byte[25] & 0x40 >> 0
```

### ca: pork

```
[MISSING] decode_field: pork
    Lua reads 'pork' from byte[25] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:363
    lua        : pork = byte[25] & 0x80 >> 0
```

### ca: mutton

```
[MISSING] decode_field: mutton
    Lua reads 'mutton' from byte[26] (mask 0x01, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:364
    lua        : mutton = byte[26] & 0x01 >> 0
```

### ca: chicken

```
[MISSING] decode_field: chicken
    Lua reads 'chicken' from byte[26] (mask 0x02, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:365
    lua        : chicken = byte[26] & 0x02 >> 0
```

### ca: duck_meat

```
[MISSING] decode_field: duck_meat
    Lua reads 'duckMeat' from byte[26] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:366
    lua        : duckMeat = byte[26] & 0x04 >> 0
```

### ca: fish

```
[MISSING] decode_field: fish
    Lua reads 'fish' from byte[26] (mask 0x08, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:367
    lua        : fish = byte[26] & 0x08 >> 0
```

### ca: shrimp

```
[MISSING] decode_field: shrimp
    Lua reads 'shrimp' from byte[26] (mask 0x10, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:368
    lua        : shrimp = byte[26] & 0x10 >> 0
```

### ca: dumplings

```
[MISSING] decode_field: dumplings
    Lua reads 'dumplings' from byte[26] (mask 0x20, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:369
    lua        : dumplings = byte[26] & 0x20 >> 0
```

### ca: glue_pudding

```
[MISSING] decode_field: glue_pudding
    Lua reads 'gluePudding' from byte[26] (mask 0x40, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:370
    lua        : gluePudding = byte[26] & 0x40 >> 0
```

### ca: ice_cream

```
[MISSING] decode_field: ice_cream
    Lua reads 'iceCream' from byte[26] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:371
    lua        : iceCream = byte[26] & 0x80 >> 0
```

### ca: performance_mode

```
[MISSING] decode_field: performance_mode
    Lua reads 'performanceMode' from byte[27] (mask 0x80, shift 0); midealocal parses nothing there
    lua source : lua/ca/T_0000_CA_5.lua:372
    lua        : performanceMode = byte[27] & 0x80 >> 0
```

### cd: energy_mode

```
[MISSING] decode_field: energy_mode
    Lua reads 'energyMode' from byte[2] (mask 0x02, shift 1); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:158
    lua        : energyMode = byte[2] & 0x02 >> 1
```

### cd: standard_mode

```
[MISSING] decode_field: standard_mode
    Lua reads 'standardMode' from byte[2] (mask 0x04, shift 2); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:159
    lua        : standardMode = byte[2] & 0x04 >> 2
```

### cd: compatibilizing_mode

```
[MISSING] decode_field: compatibilizing_mode
    Lua reads 'compatibilizingMode' from byte[2] (mask 0x08, shift 3); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:160
    lua        : compatibilizingMode = byte[2] & 0x08 >> 3
```

### cd: dicaryon_heat

```
[MISSING] decode_field: dicaryon_heat
    Lua reads 'dicaryonHeat' from byte[2] (mask 0x20, shift 5); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:162
    lua        : dicaryonHeat = byte[2] & 0x20 >> 5
```

### cd: timer1_open_hour

```
[MISSING] decode_field: timer1_open_hour
    Lua reads 'timer1OpenHour' from byte[12] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:173
    lua        : timer1OpenHour = byte[12] & 0xFF >> 0
```

### cd: timer1_open_min

```
[MISSING] decode_field: timer1_open_min
    Lua reads 'timer1OpenMin' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:174
    lua        : timer1OpenMin = byte[13] & 0xFF >> 0
```

### cd: timer1_close_hour

```
[MISSING] decode_field: timer1_close_hour
    Lua reads 'timer1CloseHour' from byte[14] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:175
    lua        : timer1CloseHour = byte[14] & 0xFF >> 0
```

### cd: timer1_close_min

```
[MISSING] decode_field: timer1_close_min
    Lua reads 'timer1CloseMin' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:176
    lua        : timer1CloseMin = byte[15] & 0xFF >> 0
```

### cd: timer2_open_hour

```
[MISSING] decode_field: timer2_open_hour
    Lua reads 'timer2OpenHour' from byte[16] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:177
    lua        : timer2OpenHour = byte[16] & 0xFF >> 0
```

### cd: timer2_open_min

```
[MISSING] decode_field: timer2_open_min
    Lua reads 'timer2OpenMin' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:178
    lua        : timer2OpenMin = byte[17] & 0xFF >> 0
```

### cd: timer2_close_hour

```
[MISSING] decode_field: timer2_close_hour
    Lua reads 'timer2CloseHour' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:179
    lua        : timer2CloseHour = byte[18] & 0xFF >> 0
```

### cd: timer2_close_min

```
[MISSING] decode_field: timer2_close_min
    Lua reads 'timer2CloseMin' from byte[19] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:180
    lua        : timer2CloseMin = byte[19] & 0xFF >> 0
```

### cd: order1_temp

```
[MISSING] decode_field: order1_temp
    Lua reads 'order1Temp' from byte[21] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:182
    lua        : order1Temp = byte[21] & 0xFF >> 0
```

### cd: order1_time_hour

```
[MISSING] decode_field: order1_time_hour
    Lua reads 'order1TimeHour' from byte[22] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:183
    lua        : order1TimeHour = byte[22] & 0xFF >> 0
```

### cd: order1_time_min

```
[MISSING] decode_field: order1_time_min
    Lua reads 'order1TimeMin' from byte[23] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:184
    lua        : order1TimeMin = byte[23] & 0xFF >> 0
```

### cd: order2_temp

```
[MISSING] decode_field: order2_temp
    Lua reads 'order2Temp' from byte[24] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:185
    lua        : order2Temp = byte[24] & 0xFF >> 0
```

### cd: order2_time_hour

```
[MISSING] decode_field: order2_time_hour
    Lua reads 'order2TimeHour' from byte[25] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:186
    lua        : order2TimeHour = byte[25] & 0xFF >> 0
```

### cd: order2_time_min

```
[MISSING] decode_field: order2_time_min
    Lua reads 'order2TimeMin' from byte[26] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:187
    lua        : order2TimeMin = byte[26] & 0xFF >> 0
```

### cd: compressor

```
[MISSING] decode_field: compressor
    Lua reads 'compressor' from byte[27] (mask 0x08, shift 3); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:191
    lua        : compressor = byte[27] & 0x08 >> 3
```

### cd: middle_wind

```
[MISSING] decode_field: middle_wind
    Lua reads 'middleWind' from byte[27] (mask 0x10, shift 4); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:192
    lua        : middleWind = byte[27] & 0x10 >> 4
```

### cd: four_way_valve

```
[MISSING] decode_field: four_way_valve
    Lua reads 'fourWayValve' from byte[27] (mask 0x20, shift 5); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:193
    lua        : fourWayValve = byte[27] & 0x20 >> 5
```

### cd: low_wind

```
[MISSING] decode_field: low_wind
    Lua reads 'lowWind' from byte[27] (mask 0x40, shift 6); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:194
    lua        : lowWind = byte[27] & 0x40 >> 6
```

### cd: high_wind

```
[MISSING] decode_field: high_wind
    Lua reads 'highWind' from byte[27] (mask 0x80, shift 7); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:195
    lua        : highWind = byte[27] & 0x80 >> 7
```

### cd: timer1_effect

```
[MISSING] decode_field: timer1_effect
    Lua reads 'timer1Effect' from byte[28] (mask 0x02, shift 1); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:196
    lua        : timer1Effect = byte[28] & 0x02 >> 1
```

### cd: timer2_effect

```
[MISSING] decode_field: timer2_effect
    Lua reads 'timer2Effect' from byte[28] (mask 0x04, shift 2); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:197
    lua        : timer2Effect = byte[28] & 0x04 >> 2
```

### cd: smart_effect

```
[MISSING] decode_field: smart_effect
    Lua reads 'smartEffect' from byte[28] (mask 0x20, shift 5); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:200
    lua        : smartEffect = byte[28] & 0x20 >> 5
```

### cd: backwater_effect

```
[MISSING] decode_field: backwater_effect
    Lua reads 'backwaterEffect' from byte[28] (mask 0x40, shift 6); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:201
    lua        : backwaterEffect = byte[28] & 0x40 >> 6
```

### cd: sterilize_effect

```
[MISSING] decode_field: sterilize_effect
    Lua reads 'sterilizeEffect' from byte[28] (mask 0x80, shift 7); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:202
    lua        : sterilizeEffect = byte[28] & 0x80 >> 7
```

### cd: control_type

```
[MISSING] decode_field: control_type
    Lua reads 'controlType' from byte[0] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:205
    lua        : controlType = byte[0] & 0xFF >> 0
```

### cd: defrost

```
[MISSING] decode_field: defrost
    Lua reads 'defrost' from byte[8] (mask 0x04, shift 2); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:216
    lua        : defrost = byte[8] & 0x04 >> 2
```

### cd: mute

```
[MISSING] decode_field: mute
    Lua reads 'mute' from byte[8] (mask 0x08, shift 3); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:217
    lua        : mute = byte[8] & 0x08 >> 3
```

### cd: open_ptc_temp

```
[MISSING] decode_field: open_ptc_temp
    Lua reads 'openPTCTemp' from byte[8] (mask 0x02, shift 6); midealocal parses nothing there
    lua source : lua/cd/T_0000_CD_3.lua:218
    lua        : openPTCTemp = byte[8] & 0x02 >> 6
```

### cf: body_type 0x07

```
[MISSING] command: body_type 0x07
    Lua builds a request with body[0]=0x07 (trigger 'query'); no midealocal Message* emits that body type
    lua source : lua/cf/T_0000_CF_4.lua:1435
```

### da: mode

```
[MISSING] decode_field: mode
    Lua reads 'mode' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/da/T_0000_DA_7.lua:297
    lua        : mode = byte[3] & 0xFF >> 0
```

### da: temperature

```
[MISSING] decode_field: temperature
    Lua reads 'temperature' from byte[15] (mask 0x0F, shift 0); midealocal parses nothing there
    lua source : lua/da/T_0000_DA_7.lua:316
    lua        : temperature = byte[15] & 0x0F >> 0
```

### db: soak_count

```
[MISSING] decode_field: soak_count
    Lua reads 'soakCount' from byte[6] (mask 0xF0, shift 4); midealocal parses nothing there
    lua source : lua/db/T_0000_DB_14.lua:390
    lua        : soakCount = byte[6] & 0xF0 >> 4
```

### db: byte13

```
[MISSING] decode_field: byte13
    Lua reads 'byte13' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/db/T_0000_DB_14.lua:394
    lua        : byte13 = byte[13] & 0xFF >> 0
```

### db: expert_step

```
[MISSING] decode_field: expert_step
    Lua reads 'expertStep' from byte[19] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/db/T_0000_DB_14.lua:398
    lua        : expertStep = byte[19] & 0xFF >> 0
```

### db: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[6] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/db/T_0000_DB_14.lua:404
    lua        : errorCode = byte[6] & 0xFF >> 0
```

### e2: mode_value1

```
[MISSING] decode_field: mode_value1
    Lua reads 'modeValue1' from byte[7] (mask 0xF3, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:210
    lua        : modeValue1 = byte[7] & 0xF3 >> 0
```

### e2: heat

```
[MISSING] decode_field: heat
    Lua reads 'heatValue' from byte[7] (mask 0x0C, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:211
    lua        : heatValue = byte[7] & 0x0C >> 0
```

### e2: mode_value2

```
[MISSING] decode_field: mode_value2
    Lua reads 'modeValue2' from byte[8] (mask 0x27, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:212
    lua        : modeValue2 = byte[8] & 0x27 >> 0
```

### e2: safe

```
[MISSING] decode_field: safe
    Lua reads 'safeValue' from byte[22] (mask 0x04, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:216
    lua        : safeValue = byte[22] & 0x04 >> 0
```

### e2: mode_value3

```
[MISSING] decode_field: mode_value3
    Lua reads 'modeValue3' from byte[23] (mask 0x0F, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:217
    lua        : modeValue3 = byte[23] & 0x0F >> 0
```

### e2: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:218
    lua        : errorCode = byte[3] & 0xFF >> 0
```

### e2: end_time_minute

```
[MISSING] decode_field: end_time_minute
    Lua reads 'endTimeMinute' from byte[10] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e2/T_0000_E2_9.lua:220
    lua        : endTimeMinute = byte[10] & 0xFF >> 0
```

### e3: change_litre

```
[MISSING] decode_field: change_litre
    Lua reads 'changeLitre' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e3/T_0000_E3_8.lua:247
    lua        : changeLitre = byte[18] & 0xFF >> 0
```

### e3: byte13

```
[MISSING] decode_field: byte13
    Lua reads 'byte13' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e3/T_0000_E3_8.lua:248
    lua        : byte13 = byte[13] & 0xFF >> 0
```

### e3: byte14

```
[MISSING] decode_field: byte14
    Lua reads 'byte14' from byte[14] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e3/T_0000_E3_8.lua:249
    lua        : byte14 = byte[14] & 0xFF >> 0
```

### e3: byte18

```
[MISSING] decode_field: byte18
    Lua reads 'byte18' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e3/T_0000_E3_8.lua:250
    lua        : byte18 = byte[18] & 0xFF >> 0
```

### e8: power

```
[MISSING] decode_field: power
    Lua reads 'powerValue' from byte[8] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:143
    lua        : powerValue = byte[8] & 0xFF >> 0
```

### e8: stage1

```
[MISSING] decode_field: stage1
    Lua reads 'stage1Value' from byte[9] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:144
    lua        : stage1Value = byte[9] & 0xFF >> 0
```

### e8: stage1_time

```
[MISSING] decode_field: stage1_time
    Lua reads 'stage1TimeValue' from byte[11] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:145
    lua        : stage1TimeValue = byte[11] & 0xFF >> 0  (messageBytes[11] * 60 + messageBytes[10])
```

### e8: stage2

```
[MISSING] decode_field: stage2
    Lua reads 'stage2Value' from byte[12] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:146
    lua        : stage2Value = byte[12] & 0xFF >> 0
```

### e8: stage2_time

```
[MISSING] decode_field: stage2_time
    Lua reads 'stage2TimeValue' from byte[14] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:147
    lua        : stage2TimeValue = byte[14] & 0xFF >> 0  (messageBytes[14] * 60 + messageBytes[13])
```

### e8: stage3

```
[MISSING] decode_field: stage3
    Lua reads 'stage3Value' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:148
    lua        : stage3Value = byte[15] & 0xFF >> 0
```

### e8: stage3_time

```
[MISSING] decode_field: stage3_time
    Lua reads 'stage3TimeValue' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:149
    lua        : stage3TimeValue = byte[17] & 0xFF >> 0  (messageBytes[17] * 60 + messageBytes[16])
```

### e8: stage_all_time

```
[MISSING] decode_field: stage_all_time
    Lua reads 'stageAllTime' from byte[19] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/e8/T_0000_E8_2.lua:150
    lua        : stageAllTime = byte[19] & 0xFF >> 0  (messageBytes[19] * 60 + messageBytes[18])
```

### ea: order_hour

```
[MISSING] decode_field: order_hour
    Lua reads 'orderHour' from byte[10] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:446
    lua        : orderHour = byte[10] & 0xFF >> 0
```

### ea: left_min

```
[MISSING] decode_field: left_min
    Lua reads 'leftMin' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:449
    lua        : leftMin = byte[13] & 0xFF >> 0
```

### ea: warm_min

```
[MISSING] decode_field: warm_min
    Lua reads 'warmMin' from byte[23] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:451
    lua        : warmMin = byte[23] & 0xFF >> 0
```

### ea: rice_type

```
[MISSING] decode_field: rice_type
    Lua reads 'riceType' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:453
    lua        : riceType = byte[15] & 0xFF >> 0  (messageBytes[15] + bit.lshift(messageBytes[16], 8))
```

### ea: voltage

```
[MISSING] decode_field: voltage
    Lua reads 'voltage' from byte[24] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:454
    lua        : voltage = byte[24] & 0xFF >> 0  (messageBytes[24] + bit.lshift(messageBytes[25], 8))
```

### ea: rice_level

```
[MISSING] decode_field: rice_level
    Lua reads 'riceLevel' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:460
    lua        : riceLevel = byte[17] & 0xFF >> 0
```

### ea: rice_cup_number

```
[MISSING] decode_field: rice_cup_number
    Lua reads 'riceCupNumber' from byte[32] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:482
    lua        : riceCupNumber = byte[32] & 0xFF >> 0
```

### ea: step_expect_time

```
[MISSING] decode_field: step_expect_time
    Lua reads 'stepExpectTime' from byte[33] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:483
    lua        : stepExpectTime = byte[33] & 0xFF >> 0  (messageBytes[33] + messageBytes[34] * 255)
```

### ea: step_actual_time

```
[MISSING] decode_field: step_actual_time
    Lua reads 'stepActualTime' from byte[35] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:484
    lua        : stepActualTime = byte[35] & 0xFF >> 0  (messageBytes[35] + messageBytes[36] * 255)
```

### ea: storage_volume_level

```
[MISSING] decode_field: storage_volume_level
    Lua reads 'storageVolumeLevel' from byte[37] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:485
    lua        : storageVolumeLevel = byte[37] & 0xFF >> 0
```

### ea: storage_temp

```
[MISSING] decode_field: storage_temp
    Lua reads 'storageTemp' from byte[38] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:486
    lua        : storageTemp = byte[38] & 0xFF >> 0
```

### ea: storage_humodity

```
[MISSING] decode_field: storage_humodity
    Lua reads 'storageHumodity' from byte[39] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:487
    lua        : storageHumodity = byte[39] & 0xFF >> 0
```

### ea: storage_expect_cup

```
[MISSING] decode_field: storage_expect_cup
    Lua reads 'storageExpectCup' from byte[40] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:488
    lua        : storageExpectCup = byte[40] & 0xFF >> 0
```

### ea: storage_type

```
[MISSING] decode_field: storage_type
    Lua reads 'storageType' from byte[41] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:489
    lua        : storageType = byte[41] & 0xFF >> 0  (messageBytes[41] + messageBytes[42] * 255)
```

### ea: left_min

```
[MISSING] decode_field: left_min
    Lua reads 'leftMin' from byte[23] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:502
    lua        : leftMin = byte[23] & 0xFF >> 0
```

### ea: warm_min

```
[MISSING] decode_field: warm_min
    Lua reads 'warmMin' from byte[27] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:504
    lua        : warmMin = byte[27] & 0xFF >> 0
```

### ea: work_stage

```
[MISSING] decode_field: work_stage
    Lua reads 'workStage' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:507
    lua        : workStage = byte[17] & 0xFF >> 0
```

### ea: voltage

```
[MISSING] decode_field: voltage
    Lua reads 'voltage' from byte[30] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:509
    lua        : voltage = byte[30] & 0xFF >> 0  (messageBytes[30] + bit.lshift(messageBytes[31], 8))
```

### ea: indoor_temperature

```
[MISSING] decode_field: indoor_temperature
    Lua reads 'indoorTemperature' from byte[32] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:512
    lua        : indoorTemperature = byte[32] & 0xFF >> 0
```

### ea: mouth_feel

```
[MISSING] decode_field: mouth_feel
    Lua reads 'mouthFeel' from byte[45] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:518
    lua        : mouthFeel = byte[45] & 0xFF >> 0
```

### ea: rice_type

```
[MISSING] decode_field: rice_type
    Lua reads 'riceType' from byte[46] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:519
    lua        : riceType = byte[46] & 0xFF >> 0  (messageBytes[46] + bit.lshift(messageBytes[47], 8))
```

### ea: order_hour

```
[MISSING] decode_field: order_hour
    Lua reads 'orderHour' from byte[48] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:521
    lua        : orderHour = byte[48] & 0xFF >> 0
```

### ea: order_min

```
[MISSING] decode_field: order_min
    Lua reads 'orderMin' from byte[49] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:522
    lua        : orderMin = byte[49] & 0xFF >> 0
```

### ea: left_min

```
[MISSING] decode_field: left_min
    Lua reads 'leftMin' from byte[51] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:524
    lua        : leftMin = byte[51] & 0xFF >> 0
```

### ea: warm_min

```
[MISSING] decode_field: warm_min
    Lua reads 'warmMin' from byte[55] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:526
    lua        : warmMin = byte[55] & 0xFF >> 0
```

### ea: work_stage

```
[MISSING] decode_field: work_stage
    Lua reads 'workStage' from byte[43] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:531
    lua        : workStage = byte[43] & 0xFF >> 0
```

### ea: work_flag

```
[MISSING] decode_field: work_flag
    Lua reads 'workFlag' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ea/T_0000_EA_15.lua:595
    lua        : workFlag = byte[15] & 0xFF >> 0
```

### ed: byte12

```
[MISSING] decode_field: byte12
    Lua reads 'byte12' from byte[2] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:100
    lua        : byte12 = byte[2] & 0xFF >> 0
```

### ed: byte13

```
[MISSING] decode_field: byte13
    Lua reads 'byte13' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:101
    lua        : byte13 = byte[3] & 0xFF >> 0
```

### ed: byte14

```
[MISSING] decode_field: byte14
    Lua reads 'byte14' from byte[4] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:102
    lua        : byte14 = byte[4] & 0xFF >> 0
```

### ed: byte15

```
[MISSING] decode_field: byte15
    Lua reads 'byte15' from byte[5] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:103
    lua        : byte15 = byte[5] & 0xFF >> 0
```

### ed: heat_temp

```
[MISSING] decode_field: heat_temp
    Lua reads 'heatTemp' from byte[10] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:105
    lua        : heatTemp = byte[10] & 0xFF >> 0
```

### ed: cool_temp

```
[MISSING] decode_field: cool_temp
    Lua reads 'coolTemp' from byte[11] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:106
    lua        : coolTemp = byte[11] & 0xFF >> 0
```

### ed: life4

```
[MISSING] decode_field: life4
    Lua reads 'life4' from byte[19] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:116
    lua        : life4 = byte[19] & 0xFF >> 0
```

### ed: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/ed/T_0000_ED_6.lua:118
    lua        : errorCode = byte[13] & 0xFF >> 0
```

### fa: mode

```
[MISSING] decode_field: mode
    Lua reads 'modeValue' from byte[4] (mask 0x0E, shift 1); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:221
    lua        : modeValue = byte[4] & 0x0E >> 1
```

### fa: gear

```
[MISSING] decode_field: gear
    Lua reads 'gearValue' from byte[5] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:222
    lua        : gearValue = byte[5] & 0xFF >> 0
```

### fa: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[1] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:226
    lua        : errorCode = byte[1] & 0xFF >> 0
```

### fa: voice

```
[MISSING] decode_field: voice
    Lua reads 'voiceValue' from byte[2] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:227
    lua        : voiceValue = byte[2] & 0xFF >> 0
```

### fa: lock

```
[MISSING] decode_field: lock
    Lua reads 'lockValue' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:228
    lua        : lockValue = byte[3] & 0xFF >> 0
```

### fa: sleep_sensor

```
[MISSING] decode_field: sleep_sensor
    Lua reads 'sleepSensor' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:229
    lua        : sleepSensor = byte[17] & 0xFF >> 0
```

### fa: scene

```
[MISSING] decode_field: scene
    Lua reads 'scene' from byte[16] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:230
    lua        : scene = byte[16] & 0xFF >> 0
```

### fa: body_feeling_scan

```
[MISSING] decode_field: body_feeling_scan
    Lua reads 'bodyFeelingScan' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:231
    lua        : bodyFeelingScan = byte[15] & 0xFF >> 0
```

### fa: temp_feedback

```
[MISSING] decode_field: temp_feedback
    Lua reads 'tempFeedback' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:232
    lua        : tempFeedback = byte[13] & 0xFF >> 0
```

### fa: hum_feedback

```
[MISSING] decode_field: hum_feedback
    Lua reads 'humFeedback' from byte[12] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:233
    lua        : humFeedback = byte[12] & 0xFF >> 0
```

### fa: anion

```
[MISSING] decode_field: anion
    Lua reads 'anion' from byte[9] (mask 0x03, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:234
    lua        : anion = byte[9] & 0x03 >> 0
```

### fa: anophelifuge

```
[MISSING] decode_field: anophelifuge
    Lua reads 'anophelifuge' from byte[9] (mask 0x0C, shift 2); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:235
    lua        : anophelifuge = byte[9] & 0x0C >> 2
```

### fa: humidity

```
[MISSING] decode_field: humidity
    Lua reads 'humidity' from byte[7] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:237
    lua        : humidity = byte[7] & 0xFF >> 0
```

### fa: temperature

```
[MISSING] decode_field: temperature
    Lua reads 'temperature' from byte[6] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:238
    lua        : temperature = byte[6] & 0xFF >> 0
```

### fa: timer_off_hour

```
[MISSING] decode_field: timer_off_hour
    Lua reads 'timerOffHour' from byte[10] (mask 0x1F, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:239
    lua        : timerOffHour = byte[10] & 0x1F >> 0
```

### fa: timer_off_minute_ten

```
[MISSING] decode_field: timer_off_minute_ten
    Lua reads 'timerOffMinuteTen' from byte[10] (mask 0xE0, shift 5); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:240
    lua        : timerOffMinuteTen = byte[10] & 0xE0 >> 5
```

### fa: timer_off_minute_bit

```
[MISSING] decode_field: timer_off_minute_bit
    Lua reads 'timerOffMinuteBit' from byte[14] (mask 0xF0, shift 4); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:241
    lua        : timerOffMinuteBit = byte[14] & 0xF0 >> 4
```

### fa: timer_on_hour

```
[MISSING] decode_field: timer_on_hour
    Lua reads 'timerOnHour' from byte[11] (mask 0x1F, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:242
    lua        : timerOnHour = byte[11] & 0x1F >> 0
```

### fa: timer_on_minute_ten

```
[MISSING] decode_field: timer_on_minute_ten
    Lua reads 'timerOnMinuteTen' from byte[11] (mask 0xE0, shift 5); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:243
    lua        : timerOnMinuteTen = byte[11] & 0xE0 >> 5
```

### fa: timer_on_minute_bit

```
[MISSING] decode_field: timer_on_minute_bit
    Lua reads 'timerOnMinuteBit' from byte[14] (mask 0x0F, shift 0); midealocal parses nothing there
    lua source : lua/fa/T_0000_FA_7.lua:244
    lua        : timerOnMinuteBit = byte[14] & 0x0F >> 0
```

### fa: body_type 0x00

```
[MISSING] command: body_type 0x00
    Lua builds a request with body[0]=0x00 (trigger 'query'); no midealocal Message* emits that body type
    lua source : lua/fa/T_0000_FA_7.lua:248
```

### fb: mode[0x00]

```
[MISSING] enum: mode[0x00]
    Lua maps 0x00 -> 'humidity_invalid'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x00 -> 'humidity_invalid'
```

### fb: mode[0x09]

```
[MISSING] enum: mode[0x09]
    Lua maps 0x09 -> 'custom'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x09 -> 'custom'
```

### fb: mode[0x20]

```
[MISSING] enum: mode[0x20]
    Lua maps 0x20 -> 'humidity_const'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x20 -> 'humidity_const'
```

### fb: mode[0x30]

```
[MISSING] enum: mode[0x30]
    Lua maps 0x30 -> 'humidity_one'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x30 -> 'humidity_one'
```

### fb: mode[0x40]

```
[MISSING] enum: mode[0x40]
    Lua maps 0x40 -> 'humidity_two'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x40 -> 'humidity_two'
```

### fb: mode[0x50]

```
[MISSING] enum: mode[0x50]
    Lua maps 0x50 -> 'humidity_three'; midealocal has no entry for that value
    lua source : lua/fb/T_0000_FB_3.lua:17
    lua        : 0x50 -> 'humidity_three'
```

### fb: humidity_mode

```
[MISSING] decode_field: humidity_mode
    Lua reads 'humidityModeValue' from byte[9] (mask 0xF0, shift 0); midealocal parses nothing there
    lua source : lua/fb/T_0000_FB_3.lua:162
    lua        : humidityModeValue = byte[9] & 0xF0 >> 0
```

### fb: lock

```
[MISSING] decode_field: lock
    Lua reads 'lockValue' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fb/T_0000_FB_3.lua:165
    lua        : lockValue = byte[18] & 0xFF >> 0
```

### fc: hour

```
[MISSING] decode_field: hour
    Lua reads 'hour' from byte[5] (mask 0x7F, shift 2); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:126
    lua        : hour = byte[5] & 0x7F >> 2
```

### fc: step_mintues

```
[MISSING] decode_field: step_mintues
    Lua reads 'stepMintues' from byte[5] (mask 0x03, shift 0); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:127
    lua        : stepMintues = byte[5] & 0x03 >> 0
```

### fc: humidify_mode

```
[MISSING] decode_field: humidify_mode
    Lua reads 'humidifyMode' from byte[8] (mask 0x70, shift 0); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:130
    lua        : humidifyMode = byte[8] & 0x70 >> 0
```

### fc: ash_tvoc

```
[MISSING] decode_field: ash_tvoc
    Lua reads 'ashTvoc' from byte[12] (mask 0x07, shift 0); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:132
    lua        : ashTvoc = byte[12] & 0x07 >> 0
```

### fc: pm25_high

```
[MISSING] decode_field: pm25_high
    Lua reads 'pm25High' from byte[14] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:137
    lua        : pm25High = byte[14] & 0xFF >> 0  ((messageBytes[14] * 256))
```

### fc: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[21] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fc/T_0000_FC_6.lua:148
    lua        : errorCode = byte[21] & 0xFF >> 0
```

### fd: error_code

```
[MISSING] decode_field: error_code
    Lua reads 'errorCode' from byte[21] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/fd/T_0000_FD_6.lua:67
    lua        : errorCode = byte[21] & 0xFF >> 0
```

### x13: cmd_type

```
[MISSING] decode_field: cmd_type
    Lua reads 'cmdType' from byte[0] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:110
    lua        : cmdType = byte[0] & 0xFF >> 0
```

### x13: brightness

```
[MISSING] decode_field: brightness
    Lua reads 'brightness' from byte[1] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:117
    lua        : brightness = byte[1] & 0xFF >> 0
```

### x13: color_temperature

```
[MISSING] decode_field: color_temperature
    Lua reads 'colorTemperature' from byte[2] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:118
    lua        : colorTemperature = byte[2] & 0xFF >> 0
```

### x13: scene_light

```
[MISSING] decode_field: scene_light
    Lua reads 'sceneLight' from byte[3] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:119
    lua        : sceneLight = byte[3] & 0xFF >> 0
```

### x13: delay_light_off

```
[MISSING] decode_field: delay_light_off
    Lua reads 'delayLightOff' from byte[4] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:120
    lua        : delayLightOff = byte[4] & 0xFF >> 0
```

### x13: color_red

```
[MISSING] decode_field: color_red
    Lua reads 'colorRed' from byte[5] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:121
    lua        : colorRed = byte[5] & 0xFF >> 0
```

### x13: color_green

```
[MISSING] decode_field: color_green
    Lua reads 'colorGreen' from byte[6] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:122
    lua        : colorGreen = byte[6] & 0xFF >> 0
```

### x13: color_blue

```
[MISSING] decode_field: color_blue
    Lua reads 'colorBlue' from byte[7] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:123
    lua        : colorBlue = byte[7] & 0xFF >> 0
```

### x13: power

```
[MISSING] decode_field: power
    Lua reads 'powerValue' from byte[8] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:124
    lua        : powerValue = byte[8] & 0xFF >> 0
```

### x13: life_brightness

```
[MISSING] decode_field: life_brightness
    Lua reads 'lifeBrightness' from byte[9] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:125
    lua        : lifeBrightness = byte[9] & 0xFF >> 0
```

### x13: life_color_temperature

```
[MISSING] decode_field: life_color_temperature
    Lua reads 'lifeColorTemperature' from byte[10] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:126
    lua        : lifeColorTemperature = byte[10] & 0xFF >> 0
```

### x13: read_brightness

```
[MISSING] decode_field: read_brightness
    Lua reads 'readBrightness' from byte[11] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:127
    lua        : readBrightness = byte[11] & 0xFF >> 0
```

### x13: read_color_temperature

```
[MISSING] decode_field: read_color_temperature
    Lua reads 'readColorTemperature' from byte[12] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:128
    lua        : readColorTemperature = byte[12] & 0xFF >> 0
```

### x13: mild_brightness

```
[MISSING] decode_field: mild_brightness
    Lua reads 'mildBrightness' from byte[13] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:129
    lua        : mildBrightness = byte[13] & 0xFF >> 0
```

### x13: mild_color_temperature

```
[MISSING] decode_field: mild_color_temperature
    Lua reads 'mildColorTemperature' from byte[14] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:130
    lua        : mildColorTemperature = byte[14] & 0xFF >> 0
```

### x13: film_brightness

```
[MISSING] decode_field: film_brightness
    Lua reads 'filmBrightness' from byte[15] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:131
    lua        : filmBrightness = byte[15] & 0xFF >> 0
```

### x13: film_color_temperature

```
[MISSING] decode_field: film_color_temperature
    Lua reads 'filmColorTemperature' from byte[16] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:132
    lua        : filmColorTemperature = byte[16] & 0xFF >> 0
```

### x13: light_brightness

```
[MISSING] decode_field: light_brightness
    Lua reads 'lightBrightness' from byte[17] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:133
    lua        : lightBrightness = byte[17] & 0xFF >> 0
```

### x13: light_color_temperature

```
[MISSING] decode_field: light_color_temperature
    Lua reads 'lightColorTemperature' from byte[18] (mask 0xFF, shift 0); midealocal parses nothing there
    lua source : lua/x13/T_0000_13_2.lua:134
    lua        : lightColorTemperature = byte[18] & 0xFF >> 0
```

### x13: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger 'power'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x02

```
[MISSING] command: body_type 0x02
    Lua builds a request with body[0]=0x02 (trigger 'scene_light'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x03

```
[MISSING] command: body_type 0x03
    Lua builds a request with body[0]=0x03 (trigger 'color_temperature'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x04

```
[MISSING] command: body_type 0x04
    Lua builds a request with body[0]=0x04 (trigger 'brightness'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x05

```
[MISSING] command: body_type 0x05
    Lua builds a request with body[0]=0x05 (trigger 'delay_light_off'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x06

```
[MISSING] command: body_type 0x06
    Lua builds a request with body[0]=0x06 (trigger 'life_color_temperature'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x07

```
[MISSING] command: body_type 0x07
    Lua builds a request with body[0]=0x07 (trigger 'read_color_temperature'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x08

```
[MISSING] command: body_type 0x08
    Lua builds a request with body[0]=0x08 (trigger 'mild_color_temperature'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x09

```
[MISSING] command: body_type 0x09
    Lua builds a request with body[0]=0x09 (trigger 'film_color_temperature'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_2.lua:189
```

### x13: body_type 0x01

```
[MISSING] command: body_type 0x01
    Lua builds a request with body[0]=0x01 (trigger None); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x02

```
[MISSING] command: body_type 0x02
    Lua builds a request with body[0]=0x02 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x03

```
[MISSING] command: body_type 0x03
    Lua builds a request with body[0]=0x03 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x04

```
[MISSING] command: body_type 0x04
    Lua builds a request with body[0]=0x04 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x31

```
[MISSING] command: body_type 0x31
    Lua builds a request with body[0]=0x31 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x32

```
[MISSING] command: body_type 0x32
    Lua builds a request with body[0]=0x32 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x33

```
[MISSING] command: body_type 0x33
    Lua builds a request with body[0]=0x33 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x13: body_type 0x34

```
[MISSING] command: body_type 0x34
    Lua builds a request with body[0]=0x34 (trigger 'control'); no midealocal Message* emits that body type
    lua source : lua/x13/T_0000_13_79010863_2024022102.lua:4164
```

### x26: body_type 0x03

```
[MISSING] command: body_type 0x03
    Lua builds a request with body[0]=0x03 (trigger 'query'); no midealocal Message* emits that body type
    lua source : lua/x26/T_0000_26_M0100032_2023091101.lua:2163
```

### x40: body_type 0x03

```
[MISSING] command: body_type 0x03
    Lua builds a request with body[0]=0x03 (trigger 'query'); no midealocal Message* emits that body type
    lua source : lua/x40/T_0000_40_M0100002_2024011701.lua:2163
```

## UNKNOWN (collapsed)

- **lua/a1/T_0000_A1_00000Q1A_2023112201.lua** (16):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump_enable: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level_set: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter_cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/a1/T_0000_A1_00000Q1B_2023112201.lua** (16):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump_enable: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level_set: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter_cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/a1/T_0000_A1_00000Q1D_2023112201.lua** (16):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump_enable: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level_set: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter_cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/a1/T_0000_A1_3.lua** (9):
  - enum/mode: Lua defines a MODE enum with 6 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump_enable: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level_set: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter_cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/a1/T_0000_A1_5.lua** (16):
  - enum/mode: Lua defines a MODE enum with 6 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pump_enable: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level_set: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter_cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ac/T_0000_AC_00000Q11_2023072401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q11_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q14_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q15_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q17_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q18_2023072401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q19_2023072401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q1B_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q1C_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_00000Q1F_2024013001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_10693145_2024092401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22.lua** (54):
  - enum/mode: Lua defines a MODE enum with 5 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - enum/fanspeed: Lua defines a FANSPEED enum with 5 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - enum/swing: Lua defines a SWING enum with 3 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/mode: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22013005_2023010601.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22013133_2024010301.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22013279_2025030601.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22013303_2025092801.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22040023_2022111101.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22040047_2022040701.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22040055_2023110201.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22040079_2024090901.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_220F4047_2025091001.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22251637_2024011201.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22259015_2023072701.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22270021_2020122401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22270043_2021101401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_22396339_2022010702.lua** (83):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_23096613_2023102401.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_23096653_2023121901.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_24.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_24296529_2024022101.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_24296693_2024071901.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0000_AC_75.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0008_AC_24.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0008_AC_26.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0008_AC_28.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/ac/T_0008_AC_29.lua** (82):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_vertical: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_horizontal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/boost_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power_saving: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/purifier: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/anion: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/kick_quilt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/full_dust: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_work_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_sleep_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/pmv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_eye: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/natural_wind: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/prevent_cold: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/frost_protect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/comfort_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing_lr: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_compressor_frequency: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_current: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_voltage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_coil_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_ambient_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_pipe_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_total: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_timeout: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_air_fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fresh_filter_time_use: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electrify_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_hour: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_operating_time_second: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/indoor_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSubProtocol to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolQuery to capture request bytes
  - introspection/note: could not instantiate MessageSubProtocolFreshAirSet to capture request bytes
- **lua/b0/T_0000_B0_0EM34A2E_6.lua** (25):
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/work_stage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tips_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fire_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_step: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/step_num: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/weight: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/people_number: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b0/T_0000_B0_0TG025JG_2021070701.lua** (25):
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/work_stage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tips_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fire_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/total_step: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/step_num: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/weight: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/people_number: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b0/T_0000_B0_6.lua** (8):
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/b1/T_0000_B1_4.lua** (7):
  - enum/mode: Lua defines a MODE enum with 9 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/b3/T_0000_B3_0090Q15S_2022012701.lua** (54):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b3/T_0000_B3_16.lua** (54):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b3/T_0000_B3_7310032C_2023021701.lua** (54):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_preheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_cooling: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/middle_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_compartment_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b4/T_0000_B4_5.lua** (9):
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b6/T_0000_B6_07.lua** (9):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/oilcup_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b6/T_0000_B6_4.lua** (3):
  - decode_field/oilcup_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/b6/T_0000_B6_5.lua** (9):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/oilcup_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b6/T_0000_B6_7300074R_2021070601.lua** (9):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/oilcup_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b6/T_0000_B6_73000J39_2021122001.lua** (9):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/oilcup_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cleaning_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/b8/T_0000_B8_6.lua** (7):
  - enum/mode: Lua defines a MODE enum with 7 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - enum/status: Lua defines a STATUS enum with 7 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSetCommand to capture request bytes
  - introspection/note: could not instantiate MessageB8GenericBody to capture request bytes
  - introspection/note: MessageB8WorkStatusBody.body raised while capturing request bytes
  - introspection/note: MessageB8NotifyBody.body raised while capturing request bytes
- **lua/b8/T_0000_B8_7500001H_2023050601.lua** (5):
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSetCommand to capture request bytes
  - introspection/note: could not instantiate MessageB8GenericBody to capture request bytes
  - introspection/note: MessageB8WorkStatusBody.body raised while capturing request bytes
  - introspection/note: MessageB8NotifyBody.body raised while capturing request bytes
- **lua/b8/T_0000_B8_750004CE_2024011101.lua** (5):
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSetCommand to capture request bytes
  - introspection/note: could not instantiate MessageB8GenericBody to capture request bytes
  - introspection/note: MessageB8WorkStatusBody.body raised while capturing request bytes
  - introspection/note: MessageB8NotifyBody.body raised while capturing request bytes
- **lua/bf/T_0000_BF_700006AG_2023092801.lua** (9):
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank_ejected: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_shortage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_change_reminder: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageBFBody to capture request bytes
- **lua/bf/T_0008_BF_2.lua** (5):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageBFBody to capture request bytes
- **lua/bf/T_0008_BF_3.lua** (6):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageBFBody to capture request bytes
- **lua/bf/T_0008_BF_4.lua** (5):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageBFBody to capture request bytes
- **lua/bf/T_0008_BF_5.lua** (5):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageBFBody to capture request bytes
- **lua/c3/T_0000_C3_17100003_2024011601.lua** (3):
  - identity/device_type: could not read device-type byte on one side
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageQuery to capture request bytes
- **lua/c3/T_0000_C3_171H120F_2023062601.lua** (3):
  - identity/device_type: could not read device-type byte on one side
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageQuery to capture request bytes
- **lua/ca/T_0000_CA_16.lua** (64):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/refrigerator_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_miachine_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_deforsting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ring_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/right_flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_high_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_electrical_machinery_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_crossing_check_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eeprom_read_write_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/left_flexzone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_room_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/main_display_correspond_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/yogurt_machine_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_fretting_switch_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_pipe_filter_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ambient_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor1_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor3_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor4_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor5_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/function_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/normal_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity_control_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/open_door_too_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_overheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_too_low: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_heating_wire_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigerator_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigerator_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/microcrystal_fresh: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_zone: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electronic_smell: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/normal_temperature_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/function_zone_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity_setting: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_left_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_right_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0000_CA_21.lua** (64):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/refrigerator_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_door_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_miachine_full: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_deforsting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ring_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/right_flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_high_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_electrical_machinery_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_crossing_check_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eeprom_read_write_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/left_flexzone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_room_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/main_display_correspond_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/yogurt_machine_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_fretting_switch_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_pipe_filter_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ambient_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor1_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor3_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor4_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor5_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/function_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/normal_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity_control_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/open_door_too_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_overheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_too_low: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_heating_wire_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigerator_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigerator_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/microcrystal_fresh: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_zone: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electronic_smell: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/normal_temperature_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/function_zone_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity_setting: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_left_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_right_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0000_CA_5.lua** (49):
  - decode_field/refrigeration_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_deforsting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ring_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/right_flex_zone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_high_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_electrical_machinery_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigeration_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_defrosting_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_crossing_check_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eeprom_read_write_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/left_flexzone_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_room_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/main_display_correspond_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/flexzone_defrosting_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/yogurt_machine_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_fretting_switch_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ice_machine_pipe_filter_overtime: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ambient_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_humidity_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor1_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor2_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor3_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor4_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/radar_sensor5_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/function_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/normal_zone_temperature_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity_control_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/open_door_too_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezing_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bar_door_alone_open_frequently: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_overheating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_temperature_too_low: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_heating_wire_sensor_error: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/refrigerator_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_setting_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/microcrystal_fresh: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_zone: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/electronic_smell: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_left_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_right_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/freezer_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_door_auto_control: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/ca/T_0008_CA_21.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_22.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_24.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_25.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_27.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_28.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ca/T_0008_CA_29.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cc/T_0000_CC_6.lua** (27):
  - enum/mode: Lua defines a MODE enum with 5 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - enum/fanspeed: Lua defines a FANSPEED enum with 8 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - enum/swing: Lua defines a SWING enum with 7 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/is_fe_format: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/night_light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ventilation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/aux_heat_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/auto_aux_heat_running: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_precision: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/swing: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temp_fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageFEControl to capture request bytes
- **lua/cd/T_0000_CD_000K86A2_3.lua** (44):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/condenser_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/max_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/min_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order1_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order2_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/typeinfo: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cd/T_0000_CD_14.lua** (45):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/condenser_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/max_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/min_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order1_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order2_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/typeinfo: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cd/T_0000_CD_3.lua** (27):
  - decode_field/heat: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/eco: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/top_elec_heat: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/water_pump: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/order1_effect: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/order2_effect: likely equivalent: Lua keeps the masked bits in place while midealocal right-aligns them; compare the enum mappings, not the raw integers
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/cd/T_0000_CD_7.lua** (44):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/condenser_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/max_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/min_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order1_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order2_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/typeinfo: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cd/T_0000_CD_RSJ000CB_8.lua** (44):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/condenser_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/max_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/min_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order1_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order2_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/typeinfo: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cd/T_0000_CD_RSJRAC01_2023070401.lua** (45):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dual_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eco: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/condenser_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/outdoor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/max_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/min_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_pump: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/compressor_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/four_way: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/elec_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order1_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/order2_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/back_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/typeinfo: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_grid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/multi_terminal: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fahrenheit: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn_tag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/maintain_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_effect: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mute_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_year: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_month: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_start_day: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/daily_timer_schedule: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/vacation_days: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/cf/T_0000_CF_4.lua** (2):
  - identity/device_type: could not read device-type byte on one side
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/da/T_0000_DA_7.lua** (4):
  - enum/mode: Lua defines a MODE enum with 3 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/soak_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softener: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detergent: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/db/T_0000_DB_14.lua** (7):
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detergent: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softener: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/stains: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dirty_degree: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/db/T_0000_DB_33.lua** (18):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/start: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/program: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detergent: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softener: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/stains: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dirty_degree: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0000_DB_41.lua** (18):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/start: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/program: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detergent: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softener: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/stains: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wash_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dehydration_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dirty_degree: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_24.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_25.lua** (5):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_26.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_27.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_29.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/db/T_0008_DB_30.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/dc/T_0000_DC_5.lua** (15):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/start: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/program: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/intensity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryness_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door_warn: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ai_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/material: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_box: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e1/T_0000_E1_22.lua** (35):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/additional: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rinse_aid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/salt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/diyflag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_set_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/doorswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/drystatus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_lack: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_step_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wrong_operation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e1/T_0000_E1_3.lua** (26):
  - decode_field/additional: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rinse_aid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/salt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/diyflag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_set_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/doorswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/drystatus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_lack: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_step_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wrong_operation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/e1/T_0000_E1_5.lua** (35):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/additional: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rinse_aid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/salt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/diyflag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_set_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/doorswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/drystatus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_lack: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_step_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wrong_operation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e1/T_0000_E1_7600644C_2022031801.lua** (35):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/additional: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rinse_aid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/salt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/diyflag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_set_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/doorswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/drystatus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_lack: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_step_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wrong_operation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e1/T_0000_E1_760RX20S_2020091803.lua** (35):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/additional: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/door: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rinse_aid: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/salt: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/lack_softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/diyflag: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_set_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/storage_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/doorswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dryswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/drystatus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterswitch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_lack: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/dry_step_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_switch: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/error_code: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/softwater: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/wrong_operation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bright: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e2/T_0000_E2_24.lua** (44):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fast_hot_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_flow: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilization: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/variable_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat_water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eplus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fast_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/half_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/whole_tank_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/summer: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/winter: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/efficient: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/night: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cloud: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/appoint_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/now_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize_high_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_cyclic: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_system: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/memory: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/day_water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e2/T_0000_E2_51021574_2022083001.lua** (43):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fast_hot_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_flow: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilization: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/variable_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heat_water_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eplus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fast_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/half_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/whole_tank_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/summer: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/winter: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/efficient: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/night: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sleep: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cloud: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/appoint_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/now_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize_high_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_cyclic: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_system: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/memory: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/day_water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e2/T_0000_E2_9.lua** (31):
  - enum/mode: Lua defines a MODE enum with 8 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/water_flow: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/variable_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/eplus: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fast_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/half_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/whole_tank_heating: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/summer: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/winter: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/efficient: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/night: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cloud: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/appoint_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/now_wash: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/sterilize_high_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/uv_sterilize: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/discharge_status: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temp: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_heat: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_cyclic: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_system: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/memory: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/day_water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/rate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/e3/T_0000_E3_1.lua** (10):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e3/T_0000_E3_11.lua** (10):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e3/T_0000_E3_511018BD_2023033101.lua** (10):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e3/T_0000_E3_511018E4_2024040701.lua** (10):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e3/T_0000_E3_511018HW_2025052801.lua** (10):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e3/T_0000_E3_8.lua** (8):
  - enum/mode: Lua defines a MODE enum with 7 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/burning_state: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_water: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/protection: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/zero_cold_pulse: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smart_volume: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/e6/T_0000_E6_2761011M_2021081901.lua** (15):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/main_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_max: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_single: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_dot: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_modes: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e6/T_0000_E6_2761013B_2022082501.lua** (15):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/main_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_max: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_single: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_dot: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_modes: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e6/T_0000_E6_9.lua** (15):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/main_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_working: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_min: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/temperature_max: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bathing_leaving_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_single: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/cold_water_dot: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_modes: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/e8/T_0000_E8_2.lua** (1):
  - identity/device_type: could not read device-type byte on one side
- **lua/ea/T_0000_EA_15.lua** (1):
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/ea/T_0000_EA_61001599_2021012601.lua** (25):
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_1.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_2.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_3.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_4.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_5.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ea/T_0008_EA_6.lua** (4):
  - identity/device_type: could not read device-type byte on one side
  - framing/header_length: Lua uses a non-standard header length; its byte offsets are in a different coordinate system than midealocal's body
  - decode_field/*: skipped byte-offset comparison: this Lua file frames bodies after a 16-byte header (T_0008 container), so its messageBytes[i] indices do not line up with midealocal's 10-byte-header body[i]
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ec/T_0000_EC_4.lua** (14):
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/with_pressure: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/progress: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/time_remaining: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/keep_warm_time: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/top_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/bottom_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/with_pressure: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_28.lua** (24):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no jsonToData(): encode side not extracted
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_6.lua** (13):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/ed/T_0000_ED_63100005_2023042701.lua** (22):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_63200860_2023041401.lua** (22):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_6320097A_2024011602.lua** (22):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_632009GC_2025090401.lua** (22):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/ed/T_0000_ED_6321898A_2021091403.lua** (22):
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life1: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life2: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/life3: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/in_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/out_tds: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/water_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/fa/T_0000_FA_17.lua** (11):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tilting_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidify: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterions: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/display_on_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fa/T_0000_FA_560000F3_2023011001.lua** (11):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tilting_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidify: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterions: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/display_on_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fa/T_0000_FA_56011CB4_2023081801.lua** (11):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tilting_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidify: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterions: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/display_on_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fa/T_0000_FA_56011CEC_2024072501.lua** (11):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillate: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/oscillation_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tilting_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/humidify: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterions: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/display_on_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fa/T_0000_FA_7.lua** (5):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/tilting_angle: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/waterions: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/display_on_off: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fb/T_0000_FB_3.lua** (3):
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/energy_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fb/T_0000_FB_5706672H_2021072201.lua** (12):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/heating_level: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/energy_consumption: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: could not instantiate MessageSet to capture request bytes
- **lua/fc/T_0000_FC_6.lua** (11):
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/standby: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/standby: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/child_lock: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter1_life: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/filter2_life: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/hcho: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/hcho: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detect_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/detect_mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/fd/T_0000_FD_202Z3119_2024110101.lua** (11):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/power: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/fan_speed: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/target_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_humidity: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/tank: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
- **lua/fd/T_0000_FD_6.lua** (5):
  - enum/fanspeed: Lua defines a FANSPEED enum with 4 values; midealocal exposes no equivalent {int: name} table (it may map these values implicitly in device code)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/screen_display: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/mode: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
- **lua/x13/T_0000_13_2.lua** (2):
  - introspection/note: MessageMainLightBody.body raised while capturing request bytes
  - introspection/note: could not instantiate MessageMainLightResponseBody to capture request bytes
- **lua/x13/T_0000_13_79010863_2024022102.lua** (3):
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: MessageMainLightBody.body raised while capturing request bytes
  - introspection/note: could not instantiate MessageMainLightResponseBody to capture request bytes
- **lua/x13/T_0000_13_M0200002_2025042802.lua** (3):
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: MessageMainLightBody.body raised while capturing request bytes
  - introspection/note: could not instantiate MessageMainLightResponseBody to capture request bytes
- **lua/x26/T_0000_26_M0100032_2023091101.lua** (3):
  - identity/device_type: could not read device-type byte on one side
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: Message26Body.body raised while capturing request bytes
- **lua/x40/T_0000_40_M0100002_2024011701.lua** (9):
  - identity/device_type: could not read device-type byte on one side
  - decode_field/light: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/ventilation: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/direction: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/current_temperature: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - decode_field/smelly_sensor: midealocal parses this field but this Lua file does not (newer protocol, another model, or Lua omission)
  - extractor/unparsed: no updateGlobalPropertyValueByByte()/binToModel(): decode side not extracted
  - introspection/note: MessageSet.body raised while capturing request bytes
  - introspection/note: could not instantiate MessageX40Body to capture request bytes

