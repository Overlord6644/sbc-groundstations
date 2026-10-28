#!/bin/sh
# cam_linkmode.sh <apfpv|wfb> - switch a dual-link camera (wyvern-ai-osd
# firmware/dual, `linkmode`) along with this VRX. Called by gsmenu.sh before
# it switches rx_mode, while the camera is still at its current address:
# 192.168.0.1 on its AP in APFPV, 10.5.0.10 over the wfb-ng tunnel in WFB.
# The camera reboots into the new mode; a camera without linkmode (a plain
# OpenIPC one) is left alone, as before.
TARGET=$1
case "$TARGET" in apfpv|wfb) ;; *) exit 0 ;; esac
. /etc/default/wifibroadcast 2>/dev/null
[ "$WIFIBROADCAST_ENABLED" = true ] && CAM=10.5.0.10 || CAM=192.168.0.1
SSH_PASS="${SSH_PASS:-12345}"

ping -c 1 -W 2 $CAM > /dev/null 2>&1 || { echo "cam_linkmode: no camera at $CAM"; exit 0; }
timeout 15 sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	-o LogLevel=ERROR -o ConnectTimeout=8 root@$CAM "
	command -v linkmode > /dev/null || { echo 'cam_linkmode: camera has no linkmode'; exit 0; }
	[ \"\$(cat /tmp/link_mode 2>/dev/null)\" = $TARGET ] && { echo 'cam_linkmode: camera already $TARGET'; exit 0; }
	linkmode $TARGET -n && (setsid sh -c 'sleep 2; reboot' > /dev/null 2>&1 < /dev/null &) &&
	echo 'cam_linkmode: camera reboots into $TARGET'"
