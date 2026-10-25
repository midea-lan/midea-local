"""Discover DA washers on the local LAN and save one selected device locally."""

import argparse
import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path

from midealocal.discover import discover


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).with_name("discovery_round2_targeted.json"))
    args = parser.parse_args()
    found = await discover()
    devices = [d for d in found.values() if d.get("type") == 0xDA and d.get("protocol") in (1, 2)]
    if not devices:
        raise SystemExit("No DA V1/V2 washer found on the current LAN. Check the washer and Wi-Fi connection.")
    print("Select your washer (device details are shown locally and are not written to source files):")
    for index, device in enumerate(devices, 1):
        print(f"{index}. IP={device.get('ip_address')} type=0x{device.get('type', 0):02X} protocol={device.get('protocol')} model={device.get('model')}")
    if len(devices) == 1:
        selected = devices[0]
    else:
        try:
            index = int(input(f"Device number [1-{len(devices)}]: "))
        except (ValueError, EOFError) as exc:
            raise SystemExit("A device selection is required.") from exc
        if not 1 <= index <= len(devices):
            raise SystemExit("Selection out of range.")
        selected = devices[index - 1]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "scan": "broadcast_user_selected_DA_V1_V2",
        "devices": [selected],
        "status": "found",
    }
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Saved local device identity to {args.output}. Keep this file private; it contains device identifiers.")


if __name__ == "__main__":
    asyncio.run(main())
