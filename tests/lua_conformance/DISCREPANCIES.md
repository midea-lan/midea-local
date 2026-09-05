# Discrepancies found by the first full run

Generated data lives in [`GENERATED_REPORT.md`](GENERATED_REPORT.md). This file
is the **human triage** of that run: what looks like a real bug, what is a
naming choice, what is a framework limitation, and what still needs a protocol
expert.

Run scope: 153 comparisons over 32 mapped device types.
Totals — MATCH 465 (identity 45, framing 94, enum 48, decode 135, command 143),
DIFFERENT 55, MISSING 277, UNKNOWN 4928 (mostly "newer Lua architecture, decode
side not statically extractable").

---

## A. Likely genuine `midealocal` bugs — worth an issue/PR

| device | finding                       | Lua evidence                                                | midealocal                           | note                                                                                                               |
| ------ | ----------------------------- | ----------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `b0`   | `mode[0x06]`                  | `hot_steam`                                                 | `host_steam`                         | almost certainly a typo in `MideaB0Device._modes`.                                                                 |
| `b0`   | `status` offset + whole table | `status = messageBytes[0] & 0x7F`, `mode = messageBytes[1]` | `status = body[1]`, `mode = body[9]` | `b0` status/mode parsing and the status enum are broadly out of step with `T_0000_B0_6.lua`; needs a full re-read. |

## B. Different logical vocabulary — probably intentional, confirm and suppress

Same protocol value, different _name_. `midealocal` tends to normalise to
Home-Assistant-style names; the Lua uses Midea marketing names. Not bugs, but
each should be eyeballed once and then documented per device.

- `e1` `mode[0x00]` `neutral_gear`→`none`, `status` `work`/`running`,
  `order`/`delay`, `power_off`/`off` — the `none` rename is a known intentional
  change. `status[0x04]` `cancel_order` vs `error` is a real divergence worth a
  look.
- `b1` / `b4` / `b0` status: `work`/`idle`, `pause`/`working`, `end`/`finished`,
  `cancel`/`standby` — one consistent vocabulary split across the washer-style
  devices.
- `fb` `mode`: `intelligent`/`auto`, `efficient`/`eco`, `fast_hot`/`fast_heating`,
  `humidity_close`/`standby`.
- `b0` `mode[0x43]` `fast_baking`/`baking`, `status[0x09]` `three_sec`/`three`.

## C. Byte-offset shifts — needs a protocol expert per device

For several device types every shared field is read from a **constant-offset
shifted** position on the two sides. Either `midealocal`'s `*GeneralMessageBody`
is aligned to a different frame base than the classic Lua `bodyBytes[0]`, or the
bare `T_0000_<TYPE>_<N>.lua` files describe an older/narrower frame than the
current one. This is the highest-value area to review — it could indicate a
wrong base assumption on one side.

| device | shift    | examples                                                                |
| ------ | -------- | ----------------------------------------------------------------------- |
| `ea`   | +40 / +3 | `top_temperature` byte 20→60, `bottom_temperature` 21→61, `mode` 4→7    |
| `da`   | +1 / +18 | `program` byte 3→4, `error_code` byte 6→24                              |
| `db`   | +1       | `mode` byte 2→3, `program` byte 3→4                                     |
| `ed`   | +6       | `life1/2/3` byte 16/17/18 → 22/23/24                                    |
| `b6`   | varies   | `light` byte 4→2, `power` mask `0x0F`→`0xFF`                            |
| `cd`   | mask     | `power` whole byte vs `& 0x01`; `water_pump` byte 8 bit0 → byte 27 bit2 |

## D. Real mask/bit differences — small, check protocol version

- `ac` `prevent_cold`: Lua `byte[10] & 0x08 >> 3`, `midealocal` `byte[10] & 0x20 >> 5`.
- `ac` `swing_lr`: Lua `swingLRValue = byte[7] & 0x03`; `midealocal` labels
  `byte[7] & 0x0C` as `# swingLRValue` but stores it as `swing_vertical`, and
  the framework matched the name to yet another attr (`byte[20] & 0x80`). The AC
  swing LR/UD naming is muddled on both sides — needs a manual pass.
- `a1` / `fd` `fan_speed`, `fb` / `cd` `power`: Lua reads the whole byte,
  `midealocal` masks off the high bits (`& 0x7F`, `& 0x01`). `midealocal` is
  arguably more correct here; low risk.

## E. Framework false positives / known limitations (do not act on these)

- **`>> N` of a full byte vs `& top-bits >> N`** — e.g. `da` `rinse_level`
  (`byte[5] >> 4` vs `(byte[5] & 0xF0) >> 4`) are identical; the extractor keeps
  Lua's implicit `0xFF` mask so the signatures differ. Could be folded into the
  right-align heuristic.
- **Multi-branch decode** — `ac` `indoor/outdoor_temperature` differ because Lua
  reads them from different bytes per `dataType`, and `midealocal` has several
  `*MessageBody` classes; only one branch/class is captured on each side.
- **`MISSING decode_field`** for Lua intermediate locals (`closeHour`,
  `openStepMintues`, `PTCValue`, `smallTemperature`) — these are timer-packing
  scratch variables, not device attributes.

## F. Coverage gaps (UNKNOWN, not discrepancies)

- Newer Lua architecture (`ac` `T_0000_AC_00000Q1*` / `_2024*`, and device types
  `b3`, `e3` newer revs, `e6`, `dc`, ...): only constants/enums extracted.
- `T_0008_*` container files: byte offsets not comparable, comparison skipped.
- 16 `lua/` device types have no `midealocal` package (`b2 b7 c1 d9 e7 e9 eb ef
f1 x10 x14 x17 x51 x70 x9a x9b`); 4 packages have no Lua (`ad c2 ce x34`).

---

## Recommended next steps

1. Fix `b0` `host_steam` → `hot_steam` (isolated, safe).
2. Review the **Category C** offset shifts device by device with someone who
   knows the frame layout — start with `ea` (+40 is large and suspicious).
3. Decide the vocabulary question (Category B) once and record the outcome here.
4. Extend the extractor for the newer Lua architecture (biggest coverage win —
   it would light up `ac`, `e3`, `c3`, `cd` newer revisions).
5. Add hand-written golden encode/decode vectors for the next few devices
   (`ac`, `a1`, `cd`) following `conformance_e1_test.py`.
