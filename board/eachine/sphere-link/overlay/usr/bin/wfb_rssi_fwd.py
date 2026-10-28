#!/usr/bin/env python3
"""wfb_rssi_fwd.py - rssi_fwd.sh's WFB half: the PC HUD's "RSSI a b" (UDP
192.168.5.100:12346) from wfb-server's stats instead of the Realtek driver.

In WFB the driver's rssi_a/rssi_b do not follow the video; wfb-server's
JSON stats (127.0.0.1:8103) give the video stream's RSSI per antenna in
dBm. Sent on the APFPV scale, 0..100 % = dBm + 100, so the HUD, its halo
and the goggles' glow keep one set of thresholds (45 % / 22 % = -55 / -78
dBm). An antenna that heard nothing in the window is -1, as rssi_fwd.sh
does. Twice a second, like rssi_fwd.sh.
"""
import json
import socket
import time

API = ("127.0.0.1", 8103)
PC = ("192.168.5.100", 12346)
WINDOW = 0.5


def connect():
    while True:
        try:
            s = socket.create_connection(API, timeout=5)
            s.settimeout(0.2)
            return s
        except OSError:
            time.sleep(1)


def pct(dbm):
    return max(0, min(100, round(dbm + 100)))


def main():
    dec = json.JSONDecoder()
    out = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock, buf, acc = connect(), "", {}
    tick = time.monotonic() + WINDOW
    while True:
        try:
            chunk = sock.recv(65536).decode("utf-8", "replace")
            if not chunk:
                sock.close()
                sock, buf = connect(), ""
        except socket.timeout:
            chunk = ""
        buf += chunk
        while True:
            buf = buf.lstrip()
            if not buf:
                break
            try:
                obj, i = dec.raw_decode(buf)
            except ValueError:
                break
            buf = buf[i:]
            if obj.get("type") == "rx" and obj.get("id") == "video rx":
                for a in obj.get("rx_ant_stats") or []:
                    r = acc.setdefault(a["ant"], [0, 0])
                    r[0] += a["rssi_avg"] * a["pkt_recv"]
                    r[1] += a["pkt_recv"]
        if time.monotonic() >= tick:
            ants = sorted(acc)[:2]
            vals = [pct(acc[a][0] / acc[a][1]) if acc[a][1] else -1 for a in ants]
            vals += [-1] * (2 - len(vals))
            try:
                out.sendto(f"RSSI {vals[0]} {vals[1]}\n".encode(), PC)
            except OSError:
                pass                     # PC not there yet: keep going
            acc = {}
            tick += WINDOW


if __name__ == "__main__":
    main()
