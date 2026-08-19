#!/bin/sh
# REC button action (pixelpilot.yaml rec: ... action).
#   Gadget mode: the DVR partition is exported as USB mass-storage, so
#   recording on the VRX would corrupt it - recording is done PC-side
#   (pcpilot). Just show a message.
#   HDMI-only (no gadget): toggle PixelPilot's own DVR via SIGUSR1.
if [ -d /sys/kernel/config/usb_gadget/g1 ]; then
	/usr/bin/osdmsg "Recording is PC-side in gadget mode"
	exit 0
fi
PP=$(pidof pixelpilot)
[ -n "$PP" ] && kill -USR1 "$PP"
