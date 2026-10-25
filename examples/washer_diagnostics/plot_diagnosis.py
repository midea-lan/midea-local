"""Render the recorded idle DA water-level samples as a dependency-free SVG."""

import csv
from datetime import datetime, timezone, timedelta
from html import escape
from pathlib import Path

BASE = Path(__file__).resolve().parent
CSV_PATHS = (BASE / "diagnosis.csv", BASE / "diagnosis_round3.csv", BASE / "live_diagnosis.csv")
SVG_PATH = BASE / "water_level_idle.svg"
WIDTH, HEIGHT = 1100, 620
LEFT, RIGHT, TOP, BOTTOM = 110, 1050, 75, 500

rows = []
for csv_path in CSV_PATHS:
    if csv_path.exists():
        with csv_path.open(encoding="utf-8-sig", newline="") as source:
            rows.extend(csv.DictReader(source))
rows = [row for row in rows if row.get("raw_wash_level", "") != ""]
if not rows:
    raise SystemExit("No real raw wash_level samples found")

times = [datetime.fromisoformat(row["timestamp_utc"]) for row in rows]
start, end = min(times), max(times)
if start == end:
    end = start + timedelta(seconds=1)

def xcoord(value: datetime) -> float:
    return LEFT + (value - start).total_seconds() / (end - start).total_seconds() * (RIGHT - LEFT)

def ycoord(value: int) -> float:
    return BOTTOM - value / 15.5 * (BOTTOM - TOP)

parts = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">',
    '<rect width="100%" height="100%" fill="white"/>',
    '<style>text{font-family:Segoe UI,Arial,sans-serif;fill:#222}.grid{stroke:#d9dee5;stroke-width:1}.axis{stroke:#333;stroke-width:1.3}.small{font-size:12px}.label{font-size:14px}.title{font-size:21px;font-weight:600}</style>',
    '<text x="110" y="35" class="title">TB80-6288WCLS DA replies — every recorded sample reported progress=idle</text>',
]
# Grid and y-axis ticks, including 15 which the Python library does not translate.
for level in list(range(0, 9)) + [15]:
    y = ycoord(level)
    parts.append(f'<line x1="{LEFT}" y1="{y:.1f}" x2="{RIGHT}" y2="{y:.1f}" class="grid"/>')
    tick = "15 (unmapped)" if level == 15 else str(level)
    parts.append(f'<text x="{LEFT-14}" y="{y+4:.1f}" text-anchor="end" class="small">{tick}</text>')
parts.extend([
    f'<line x1="{LEFT}" y1="{TOP}" x2="{LEFT}" y2="{BOTTOM}" class="axis"/>',
    f'<line x1="{LEFT}" y1="{BOTTOM}" x2="{RIGHT}" y2="{BOTTOM}" class="axis"/>',
    f'<text x="28" y="290" transform="rotate(-90 28 290)" text-anchor="middle" class="label">raw wash_level nibble (not measured water volume)</text>',
])
# Six time ticks in local UTC+08:00.
for i in range(6):
    t = start + (end - start) * i / 5
    x = xcoord(t)
    parts.append(f'<line x1="{x:.1f}" y1="{BOTTOM}" x2="{x:.1f}" y2="{BOTTOM+5}" class="axis"/>')
    local = t.astimezone(timezone(timedelta(hours=8)))
    parts.append(f'<text x="{x:.1f}" y="{BOTTOM+23}" text-anchor="middle" class="small">{local:%H:%M:%S}</text>')

# Draw independent line segments; do not imply continuity across long gaps.
colors = {False: "#315c9b", True: "#167d5a"}
groups = {False: [], True: []}
for row, t in zip(rows, times, strict=True):
    y = int(row["raw_wash_level"])
    noted = bool(row.get("operator_note"))
    groups[noted].append((t, y, row))
for noted, points in groups.items():
    color = colors[noted]
    segment = []
    last_t = None
    for t, value, row in points + [(None, 0, {})]:
        if last_t is not None and (t is None or (t - last_t).total_seconds() > 30):
            if len(segment) > 1:
                coords = " ".join(f'{xcoord(pt[0]):.1f},{ycoord(pt[1]):.1f}' for pt in segment)
                parts.append(f'<polyline points="{coords}" fill="none" stroke="{color}" stroke-width="2"/>')
            segment = []
        if t is not None:
            segment.append((t, value, row))
            last_t = t
    for t, value, row in points:
        x, y = xcoord(t), ycoord(value)
        body_type = row.get("raw_body_type") or (row.get("raw_body_hex", "")[:2] if row.get("raw_body_hex") else "")
        if body_type in ("3", "03"):
            parts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4.8" fill="{color}"/>')
        else:
            parts.append(f'<path d="M{x:.1f},{y-5:.1f} l5,5 l-5,5 l-5,-5 z" fill="{color}"/>')
        if value == 15:
            parts.append(f'<text x="{x+7:.1f}" y="{y-7:.1f}" class="small">15 sentinel</text>')

reported = [datetime.fromisoformat(row["timestamp_utc"]) for row in rows if row.get("operator_note")]
if reported:
    x = xcoord(min(reported))
    parts.append(f'<line x1="{x:.1f}" y1="{TOP}" x2="{x:.1f}" y2="{BOTTOM}" stroke="#167d5a" stroke-dasharray="5,5" opacity="0.6"/>')
    parts.append(f'<text x="{min(x+6, RIGHT-210):.1f}" y="{TOP+16}" class="small">first sample with user cover note</text>')

parts.extend([
    '<circle cx="790" cy="555" r="5" fill="#315c9b"/><text x="802" y="559" class="small">condition not recorded</text>',
    '<circle cx="970" cy="555" r="5" fill="#167d5a"/><text x="982" y="559" class="small">cover removed per user report</text>',
    '<text x="110" y="590" class="small">No wash/rinse cycle sampled. Cover removal time was not independently timestamped; body replies 0x03 and 0x04 are both retained.</text>',
    '</svg>',
])
SVG_PATH.write_text("\n".join(parts), encoding="utf-8")
print(SVG_PATH)
