"""Read-only Midea LAN discovery for the washer diagnostics workspace."""

import argparse
import asyncio
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPOSITORY_ROOT))

from midealocal.discover import discover  # noqa: E402


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", help="Optional device IP to probe instead of broadcast")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).with_name("discovery.json"),
        help="JSON output path (default: washer_diagnostics/discovery.json)",
    )
    args = parser.parse_args()

    devices = await discover(ip_address=args.host)
    result = {
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "scan": "host" if args.host else "broadcast",
        "host": args.host,
        "devices": list(devices.values()),
        "status": "found" if devices else "no_devices_found",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    asyncio.run(main())

