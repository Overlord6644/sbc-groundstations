#!/usr/bin/env python3
"""msp_relay - share the camera's FC telemetry on the VRX.

The camera's msposd forwards the flight controller's telemetry (-o) to the
address the video goes to, this VRX, on UDP 14560. Two readers want it: the
local msposd that draws the moving map into PixelPilot (on 14561), and
pcpilot on the PC behind the USB gadget (192.168.5.100:14560, the address
udhcpd_usb0 reserves for it). A port has one reader, so this hands each
datagram to both. The PC leg simply fails while no PC is plugged in.

The FC may speak MSP or MAVLink (whichever Betaflight's Ports tab gives the
camera's UART; the camera's msposd follows it). pcpilot reads both; the
local msposd needs -M for MAVLink, so the protocol of what passes here is
watched and /etc/default/msposd follows it, msposd restarted on a change.
MSP frames come in both cases (the camera's own text messages), so only the
presence of MAVLink decides: seen lately = MAVLink, gone for a while = MSP.
"""
import re
import socket
import subprocess
import time

IN = ("0.0.0.0", 14560)
OUTS = [("127.0.0.1", 14561), ("192.168.5.100", 14560)]
DEFAULTS = "/etc/default/msposd"
TO_MAVLINK = 10        # MAVLink datagrams within WINDOW s before switching to it
WINDOW = 3.0
TO_MSP = 15.0          # s without MAVLink, while MSP keeps coming, to switch back


def is_mavlink(data):
    return data[:1] in (b"\xfd", b"\xfe")


def ground_is_mavlink():
    try:
        with open(DEFAULTS) as f:
            m = re.search(r'^MSPOSD_ARGS="([^"]*)"', f.read(), re.M)
        return bool(m and re.search(r"(^| )-M( |$)", m.group(1)))
    except OSError:
        return False


def set_ground(mavlink):
    try:
        with open(DEFAULTS) as f:
            text = f.read()
    except OSError:
        return

    def fix(m):
        args = re.sub(r"(^| )-M(?= |$)", "", m.group(1)).strip()
        return 'MSPOSD_ARGS="%s"' % (args + " -M" if mavlink else args)

    with open(DEFAULTS + ".new", "w") as f:
        f.write(re.sub(r'^MSPOSD_ARGS="([^"]*)"', fix, text, count=1, flags=re.M))
    subprocess.run(["mv", DEFAULTS + ".new", DEFAULTS])
    # not "restart": the new msposd started while the old one still held
    # :14561 and exited on the bind. Stop, let the port go, start.
    init = "/etc/init.d/S98msposd"
    q = {"stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
    subprocess.run([init, "stop"], **q)
    for _ in range(2):
        time.sleep(2)
        subprocess.run([init, "start"], **q)
        time.sleep(1)
        if subprocess.run(["pidof", "msposd"], **q).returncode == 0:
            break


rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
rx.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
rx.bind(IN)
tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
mavlink = ground_is_mavlink()
recent = []            # arrival times of MAVLink datagrams, the last WINDOW s
last_mav = time.monotonic() if mavlink else 0.0

while True:
    data = rx.recv(4096)
    for dst in OUTS:
        try:
            tx.sendto(data, dst)
        except OSError:
            pass
    now = time.monotonic()
    if is_mavlink(data):
        last_mav = now
        recent = [t for t in recent if now - t < WINDOW] + [now]
        if not mavlink and len(recent) >= TO_MAVLINK:
            mavlink = True
            set_ground(True)
    elif data[:1] == b"$" and mavlink and now - last_mav > TO_MSP:
        mavlink = False
        set_ground(False)
