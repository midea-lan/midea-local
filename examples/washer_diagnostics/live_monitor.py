"""Localhost-only, read-only live DA washer monitor (no control endpoints)."""

import argparse
import asyncio
import csv
import json
import sys
import webbrowser
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Unpack

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from midealocal.const import ProtocolVersion  # noqa: E402
from midealocal.device import MideaDeviceInitKwargs  # noqa: E402
from midealocal.devices.da import MideaDADevice  # noqa: E402
from midealocal.devices.da.message import MessageDAResponse  # noqa: E402
from midealocal.discover import discover  # noqa: E402

BASE = Path(__file__).resolve().parent
ALL_FIELDS = (
    "power", "start", "error_code", "program", "progress", "time_remaining",
    "wash_time", "soak_time", "dehydration_time", "dehydration_speed",
    "rinse_count", "rinse_level", "wash_level", "wash_strength", "softener", "detergent",
)
CSV_FIELDS = ("timestamp_utc", "device_ip", *ALL_FIELDS, "raw_program", "raw_wash_level", "raw_message_type", "raw_body_type", "raw_body_hex")


def json_value(value: Any) -> Any:
    if hasattr(value, "value"):
        return value.value
    if isinstance(value, dict):
        return {str(k): json_value(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [json_value(v) for v in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    return str(value)


class MonitorDevice(MideaDADevice):
    def __init__(self, *, customize: str, **kwargs: Unpack[MideaDeviceInitKwargs]) -> None:
        super().__init__(customize=customize, **kwargs)
        self.raw: dict[str, int | str] = {}

    def process_message(self, msg: bytes) -> dict[str, Any]:
        parsed = MessageDAResponse(msg)
        if hasattr(parsed, "program"):
            self.raw = {
                "raw_program": parsed.program,
                "raw_wash_level": parsed.wash_level,
                "raw_message_type": int(parsed.message_type),
                "raw_body_type": int(parsed.body_type),
                "raw_body_hex": parsed.body.hex(),
            }
        return super().process_message(msg)


def page() -> bytes:
    return PAGE.encode("utf-8")


PAGE = r'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>洗衣机只读实时监测</title>
<style>
body{font:16px system-ui,"Microsoft YaHei",sans-serif;background:#f4f6f8;color:#17202a;margin:0;padding:20px}main{max-width:1180px;margin:auto}.top,.card,.panel{background:white;border-radius:12px;padding:16px;margin-bottom:14px;box-shadow:0 1px 5px #0001}.top{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}h1{font-size:22px;margin:0}.badge{padding:7px 12px;border-radius:20px;background:#eee}.ok{background:#d9f5e6;color:#145a32}.bad{background:#fde2e2;color:#922b21}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));gap:10px}.card{margin:0}.label{font-size:13px;color:#65727e}.value{font-size:22px;font-weight:650;margin-top:5px;word-break:break-word}.note{color:#566573;font-size:14px}canvas{width:100%;height:300px}table{width:100%;border-collapse:collapse}td{padding:8px;border-bottom:1px solid #eee;vertical-align:top}td:first-child{width:190px;color:#566573}.raw{font:13px ui-monospace,monospace;overflow-wrap:anywhere}.alert{color:#922b21;font-weight:700}
</style><main><section class="top"><div><h1>TB80-6288WCLS 局域网只读实时监测</h1><div class="note">只查询，不含启动、停止、设定或复位按钮。默认每 1 秒采样。</div></div><div id="conn" class="badge">正在连接…</div></section>
<section class="grid" id="cards"></section><section class="panel"><h2>水位回报趋势（设备原始设定码）</h2><canvas id="chart" width="1100" height="300"></canvas><div class="note">曲线显示主控返回的 wash_level 原始值，不代表桶内实际水量。点线之间可能有采样间隔。</div></section>
<section class="panel"><h2>所有实际回报属性与原始报文</h2><table id="details"></table></section><section class="panel"><div class="note">上次成功采样：<span id="when">等待数据</span>　最近异常：<span id="err">无</span></div><div id="warning" class="alert"></div></section></main>
<script>
const fields=[['power','电源 power'],['start','运行 start'],['error_code','错误码'],['program','程序（库翻译）'],['raw_program','程序原始码'],['progress','阶段 progress'],['wash_level','洗涤水位（翻译）'],['raw_wash_level','洗涤水位原始码'],['rinse_level','漂洗水位'],['wash_time','洗涤时间'],['soak_time','浸泡时间'],['dehydration_time','脱水时间'],['dehydration_speed','脱水速度'],['rinse_count','漂洗次数'],['wash_strength','洗涤强度'],['softener','柔顺剂设定'],['detergent','洗涤剂设定'],['time_remaining','剩余时间']];
let history=[];function val(v){return v===null||v===undefined?'—':String(v)}
function draw(d){const c=document.getElementById('conn');c.textContent=d.connected?'已连接 · '+d.ip+':'+d.port+' · DA V'+d.protocol:'连接/查询异常';c.className='badge '+(d.connected?'ok':'bad');if(d.latest){const x=d.latest;document.getElementById('when').textContent=x.timestamp_utc;document.getElementById('err').textContent=d.last_error||'无';history=d.history||[];document.getElementById('cards').innerHTML=fields.slice(0,8).map(([k,n])=>`<article class="card"><div class="label">${n}</div><div class="value">${val(x[k])}</div></article>`).join('');document.getElementById('details').innerHTML=Object.entries(x).map(([k,v])=>`<tr><td>${k}</td><td class="raw">${val(v)}</td></tr>`).join('');const warn=document.getElementById('warning');warn.textContent=(x.error_code!==null&&x.error_code!==0)?'设备上报非零错误码：'+x.error_code:'';plot()}}
function plot(){const cv=document.getElementById('chart'),ctx=cv.getContext('2d'),w=cv.width,h=cv.height,p=38;ctx.clearRect(0,0,w,h);ctx.font='12px sans-serif';for(let n=0;n<=15;n+=3){let y=h-p-(n/15)*(h-2*p);ctx.strokeStyle='#dfe4e8';ctx.beginPath();ctx.moveTo(p,y);ctx.lineTo(w-p,y);ctx.stroke();ctx.fillStyle='#566573';ctx.fillText(n,p-26,y+4)}const a=history.filter(x=>Number.isFinite(Number(x.raw_wash_level)));if(a.length<1)return;const lo=Date.parse(a[0].timestamp_utc),hi=Date.parse(a[a.length-1].timestamp_utc)||lo+1;ctx.strokeStyle='#2471a3';ctx.lineWidth=2;ctx.beginPath();a.forEach((x,i)=>{const xx=p+(Date.parse(x.timestamp_utc)-lo)/(hi-lo||1)*(w-2*p),yy=h-p-(Number(x.raw_wash_level)/15)*(h-2*p);if(i===0)ctx.moveTo(xx,yy);else ctx.lineTo(xx,yy)});ctx.stroke();a.forEach(x=>{let xx=p+(Date.parse(x.timestamp_utc)-lo)/(hi-lo||1)*(w-2*p),yy=h-p-(Number(x.raw_wash_level)/15)*(h-2*p);ctx.fillStyle='#2471a3';ctx.beginPath();ctx.arc(xx,yy,3,0,2*Math.PI);ctx.fill()})}
async function poll(){try{const r=await fetch('/api/status',{cache:'no-store'});draw(await r.json())}catch(e){document.getElementById('conn').textContent='监测服务暂不可用'}}poll();setInterval(poll,1000);
</script></html>'''


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device-file", type=Path, default=BASE / "discovery_round2_targeted.json")
    parser.add_argument("--refresh-discovery", action="store_true", help="Rediscover the saved washer ID before connecting")
    parser.add_argument("--open-browser", action="store_true", help="Open the local dashboard when ready")
    parser.add_argument("--host", default="127.0.0.1", help="Must remain localhost-only")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--interval", type=float, default=1.0)
    parser.add_argument("--duration-seconds", type=float, default=None)
    args = parser.parse_args()
    if args.host not in ("127.0.0.1", "localhost", "::1"):
        parser.error("For privacy, the dashboard may bind only to localhost")
    if args.interval < 1:
        parser.error("--interval must be at least 1 second")
    saved_devices = json.loads(args.device_file.read_text(encoding="utf-8")).get("devices", [])
    if not saved_devices:
        raise SystemExit("Saved discovery file has no device identity to verify")
    saved = saved_devices[0]
    if args.refresh_discovery:
        found = await discover()
        matches = [d for d in found.values() if d.get("device_id") == saved.get("device_id") and d.get("type") == saved.get("type")]
        if len(matches) != 1:
            raise SystemExit("Could not uniquely rediscover the previously identified washer on this LAN")
        info = matches[0]
        refreshed = {
            "captured_at_utc": datetime.now(timezone.utc).isoformat(),
            "scan": "broadcast_identity_match",
            "devices": [info],
            "status": "found",
        }
        (BASE / "discovery_latest.json").write_text(
            json.dumps(refreshed, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
    else:
        info = saved
    if info.get("type") != 0xDA or info.get("protocol") not in (1, 2):
        raise SystemExit("Only previously identified DA V1/V2 devices are supported; refusing protocol changes/auth fallback")
    device = MonitorDevice(
        device_id=info["device_id"], name=str(info["device_id"]), ip_address=info["ip_address"],
        port=info["port"], token="", key="", device_protocol=ProtocolVersion(info["protocol"]),
        model=info["model"], subtype=0, customize="", mac=info.get("mac"),
        serial_number=info.get("sn"), manufacturer_code=info.get("manufacturer_code"),
    )
    shared: dict[str, Any] = {"connected": False, "ip": info["ip_address"], "port": info["port"], "protocol": info["protocol"], "latest": None, "history": [], "last_error": None}
    out_csv = (BASE / "live_diagnosis.csv").open("a", newline="", encoding="utf-8-sig")
    out_jsonl = (BASE / "live_diagnosis.jsonl").open("a", encoding="utf-8")
    writer = csv.DictWriter(out_csv, fieldnames=CSV_FIELDS)
    if out_csv.tell() == 0:
        writer.writeheader()

    async def sampler() -> None:
        failures = 0
        connected_session = False
        started = asyncio.get_running_loop().time()
        try:
            while args.duration_seconds is None or asyncio.get_running_loop().time() - started < args.duration_seconds:
                try:
                    if not connected_session:
                        connected_session = await device.connect()
                        if not connected_session:
                            raise ConnectionError("TCP connect failed")
                    device.raw = {}
                    await device.refresh_status(check_protocol=True)
                    row = {str(k): json_value(v) for k, v in device.attributes.items()}
                    row.update(device.raw)
                    row["timestamp_utc"] = datetime.now(timezone.utc).isoformat()
                    row["device_ip"] = info["ip_address"]
                    shared.update(connected=True, latest=row, last_error=None)
                    shared["history"].append(row)
                    del shared["history"][:-1200]
                    writer.writerow({k: row.get(k) for k in CSV_FIELDS})
                    out_csv.flush()
                    out_jsonl.write(json.dumps(row, ensure_ascii=False) + "\n")
                    out_jsonl.flush()
                    failures = 0
                except Exception as exc:  # bounded retry; never logs credentials
                    failures += 1
                    connected_session = False
                    shared.update(connected=False, last_error=type(exc).__name__)
                    if failures >= 3:
                        shared["last_error"] = f"stopped after 3 failures ({type(exc).__name__})"
                        break
                    await device.close_socket()
                    await asyncio.sleep(10)
                    continue
                await asyncio.sleep(args.interval)
        finally:
            await device.close_socket()
            out_csv.close()
            out_jsonl.close()

    async def serve(reader: asyncio.StreamReader, writer_stream: asyncio.StreamWriter) -> None:
        try:
            request = await asyncio.wait_for(reader.readline(), timeout=3)
            parts = request.decode("ascii", "replace").split()
            while await asyncio.wait_for(reader.readline(), timeout=3) not in (b"\r\n", b"\n", b""):
                pass
            if len(parts) < 2 or parts[0] != "GET":
                status, content_type, body = "405 Method Not Allowed", "text/plain; charset=utf-8", b"GET only"
            elif parts[1] == "/api/status":
                status, content_type, body = "200 OK", "application/json; charset=utf-8", json.dumps(shared, ensure_ascii=False).encode("utf-8")
            elif parts[1] == "/":
                status, content_type, body = "200 OK", "text/html; charset=utf-8", page()
            else:
                status, content_type, body = "404 Not Found", "text/plain; charset=utf-8", b"Not found"
            writer_stream.write(f"HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {len(body)}\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".encode("ascii") + body)
            await writer_stream.drain()
        except (asyncio.TimeoutError, ConnectionError):
            pass
        finally:
            writer_stream.close()
            await writer_stream.wait_closed()

    try:
        server = await asyncio.start_server(serve, args.host, args.port)
    except OSError as exc:
        out_csv.close()
        out_jsonl.close()
        raise SystemExit(f"Could not bind localhost dashboard: {type(exc).__name__}") from exc
    if args.duration_seconds is None:
        print(f"Read-only monitor ready: http://127.0.0.1:{args.port}/", flush=True)
    if args.open_browser:
        webbrowser.open(f"http://127.0.0.1:{args.port}/")
    async with server:
        await asyncio.gather(sampler(), server.serve_forever())


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Monitor stopped; no device control was sent.", file=sys.stderr)
