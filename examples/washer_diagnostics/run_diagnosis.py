"""Bounded, read-only status sampling for a discovered DA washer."""

import argparse
import asyncio
import csv
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Unpack

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from midealocal.const import ProtocolVersion  # noqa: E402
from midealocal.devices.da import MideaDADevice  # noqa: E402
from midealocal.devices.da.message import MessageDAResponse  # noqa: E402
from midealocal.device import MideaDeviceInitKwargs  # noqa: E402

DIAG_DIR = Path(__file__).resolve().parent
FIELDS = (
    "power", "start", "error_code", "program", "progress", "wash_level",
    "rinse_level", "wash_time", "rinse_count", "time_remaining",
)
CSV_FIELDS = (
    "timestamp_utc",
    "label",
    *FIELDS,
    "raw_program",
    "raw_wash_level",
    "raw_message_type",
    "raw_body_type",
    "raw_body_hex",
    "operator_note",
)


class DiagnosticDADevice(MideaDADevice):
    """DA adapter that retains raw protocol values alongside translations."""

    def __init__(
        self,
        *,
        customize: str,
        **kwargs: Unpack[MideaDeviceInitKwargs],
    ) -> None:
        super().__init__(customize=customize, **kwargs)
        self.last_raw: dict[str, int | str] = {}

    def process_message(self, msg: bytes) -> dict[str, Any]:
        parsed = MessageDAResponse(msg)
        if hasattr(parsed, "program"):
            self.last_raw = {
                "raw_program": parsed.program,
                "raw_wash_level": parsed.wash_level,
                "raw_message_type": int(parsed.message_type),
                "raw_body_type": int(parsed.body_type),
                "raw_body_hex": parsed.body.hex(),
            }
        return super().process_message(msg)


def load_device(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    devices = data.get("devices", [])
    if len(devices) != 1:
        raise SystemExit(f"Expected exactly one discovered device in {path}")
    device = devices[0]
    if device.get("type") != 0xDA:
        raise SystemExit(f"Refusing DA parser for device type {device.get('type')!r}")
    if device.get("protocol") not in (1, 2, 3):
        raise SystemExit(f"Unsupported protocol value {device.get('protocol')!r}")
    return device


def prepare_csv(path: Path) -> bool:
    """Create the CSV header or extend an earlier schema while retaining rows."""
    if not path.exists() or path.stat().st_size == 0:
        return True
    with path.open(newline="", encoding="utf-8-sig") as source:
        reader = csv.DictReader(source)
        if reader.fieldnames == list(CSV_FIELDS):
            return False
        previous_rows = []
        for row in reader:
            overflow = row.pop(None, [])
            if overflow:
                # Earlier development snapshots had a shorter CSV header.
                # Retain the original body hex from the overflow column.
                row["raw_body_hex"] = overflow[-1]
            previous_rows.append(row)
    temporary_path = path.with_suffix(".csv.tmp")
    with temporary_path.open("w", newline="", encoding="utf-8-sig") as target:
        writer = csv.DictWriter(target, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(previous_rows)
    temporary_path.replace(path)
    return False


async def run(args: argparse.Namespace) -> None:
    info = load_device(args.device_file)
    protocol = ProtocolVersion(info["protocol"])
    if protocol == ProtocolVersion.V3:
        raise SystemExit("V3 requires a valid token/key; no credential input or fallback is implemented")
    device = DiagnosticDADevice(
        device_id=info["device_id"], name=str(info["device_id"]),
        ip_address=info["ip_address"], port=info["port"], token="", key="",
        device_protocol=protocol, model=info["model"], subtype=0, customize="",
        mac=info.get("mac"), serial_number=info.get("sn"),
        manufacturer_code=info.get("manufacturer_code"),
    )
    csv_path = args.csv_output
    jsonl_path = args.jsonl_output
    log_path = args.log_output
    for output_path in (csv_path, jsonl_path, log_path):
        output_path.parent.mkdir(parents=True, exist_ok=True)
    write_header = prepare_csv(csv_path)
    csv_file = csv_path.open("a", newline="", encoding="utf-8-sig")
    jsonl_file = jsonl_path.open("a", encoding="utf-8")
    log_file = log_path.open("a", encoding="utf-8")
    writer = csv.DictWriter(csv_file, fieldnames=CSV_FIELDS)
    if write_header:
        writer.writeheader()
    started = asyncio.get_running_loop().time()
    interval = args.interval
    failures = 0
    try:
        if not await device.connect():
            raise ConnectionError("TCP connection failed")
        while args.duration_seconds is None or asyncio.get_running_loop().time() - started < args.duration_seconds:
            row = {
                "timestamp_utc": datetime.now(timezone.utc).isoformat(),
                "label": args.label,
                "operator_note": args.note,
            }
            try:
                device.last_raw = {}
                await device.refresh_status(check_protocol=True)
                attrs = device.attributes
                for field in FIELDS:
                    value = attrs.get(field)
                    row[field] = value.value if hasattr(value, "value") else value
                row.update(device.last_raw)
                writer.writerow(row)
                csv_file.flush()
                jsonl_file.write(json.dumps(row, ensure_ascii=False) + "\n")
                jsonl_file.flush()
                log_file.write(f"{row['timestamp_utc']} INFO query_ok label={args.label}\n")
                log_file.flush()
                failures = 0
                interval = args.interval
                print(json.dumps(row, ensure_ascii=False), flush=True)
            except Exception as exc:  # bounded retry; never logs payloads or credentials
                failures += 1
                print(f"Read-only query failed ({type(exc).__name__}); failure {failures}/3", file=sys.stderr, flush=True)
                log_file.write(
                    f"{datetime.now(timezone.utc).isoformat()} WARNING "
                    f"query_failed type={type(exc).__name__} retry={failures}/3\n"
                )
                log_file.flush()
                if failures >= 3:
                    print("Stopping after three consecutive query failures", file=sys.stderr)
                    break
                interval = 10.0
                await asyncio.sleep(interval)
                await device.close_socket()
                if not await device.connect():
                    failures += 1
                    log_file.write(
                        f"{datetime.now(timezone.utc).isoformat()} WARNING "
                        f"reconnect_failed retry={failures}/3\n"
                    )
                    log_file.flush()
                    if failures >= 3:
                        break
                continue
            await asyncio.sleep(interval)
    finally:
        csv_file.close()
        jsonl_file.close()
        log_file.close()
        await device.close_socket()


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--label", required=True, choices=(
        "idle", "standard_level7", "down_jacket_level7", "wash_abnormal",
        "rinse1_normal", "rinse2_normal",
    ))
    parser.add_argument("--interval", type=float, default=5.0, help="Sample interval in seconds (minimum 5)")
    parser.add_argument("--duration-seconds", type=float, default=None, help="Optional bounded run; Ctrl+C also stops safely")
    parser.add_argument(
        "--note",
        default="",
        choices=("", "top_cover_removed_user_report", "cover_reinstalled_user_report"),
        help="Optional controlled condition marker; arbitrary text is not stored",
    )
    parser.add_argument("--device-file", type=Path, default=DIAG_DIR / "discovery_round2_targeted.json")
    parser.add_argument("--csv-output", type=Path, default=DIAG_DIR / "diagnosis.csv")
    parser.add_argument("--jsonl-output", type=Path, default=DIAG_DIR / "diagnosis.jsonl")
    parser.add_argument("--log-output", type=Path, default=DIAG_DIR / "diagnosis.log")
    args = parser.parse_args()
    if args.interval < 5:
        parser.error("--interval must be at least 5 seconds")
    if args.duration_seconds is not None and args.duration_seconds <= 0:
        parser.error("--duration-seconds must be positive")
    await run(args)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Stopped by user; device was not controlled.", file=sys.stderr)


