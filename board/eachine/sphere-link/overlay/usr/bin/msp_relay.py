#!/usr/bin/env python3
"""msp_relay - share the camera's FC telemetry on the VRX.

The camera's msposd forwards the flight controller's MSP (-o) to the address
the video goes to, this VRX, on UDP 14560. Two readers want it: the local
msposd that draws the moving map into PixelPilot (on 14561), and pcpilot on
the PC behind the USB gadget (192.168.5.100:14560, the address udhcpd_usb0
reserves for it). A port has one reader, so this hands each datagram to both.
The PC leg simply fails while no PC is plugged in.
"""
import socket

IN = ("0.0.0.0", 14560)
OUTS = [("127.0.0.1", 14561), ("192.168.5.100", 14560)]

rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
rx.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
rx.bind(IN)
tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while True:
    data = rx.recv(4096)
    for dst in OUTS:
        try:
            tx.sendto(data, dst)
        except OSError:
            pass
