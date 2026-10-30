#!/bin/sh
# cam_linkmode.sh <apfpv|wfb> - switch a dual-link camera (wyvern-ai-osd
# firmware/dual, `linkmode`) along with this VRX. Called by gsmenu.sh before
# it switches rx_mode, while the camera is still at its current address:
# 192.168.0.1 on its AP in APFPV, 10.5.0.10 over the wfb-ng tunnel in WFB.
# The camera reboots into the new mode; a camera without linkmode (a plain
# OpenIPC one) is left alone, as before.
#
# Exit 0: the camera took it, was already there, has no linkmode, or is not
# there at all (nothing to keep in step). Exit 1: the camera answers but the
# order did not go through - the caller must then NOT switch, or the two end
# up in different modes with no link and no way to talk to the camera. That
# is what happened WFB -> APFPV: the order goes by ssh over the tunnel, and a
# busy camera's dropbear took longer than the 15 s it was given.
TARGET=$1
case "$TARGET" in apfpv|wfb) ;; *) exit 0 ;; esac
. /etc/default/wifibroadcast 2>/dev/null
[ "$WIFIBROADCAST_ENABLED" = true ] && CAM=10.5.0.10 || CAM=192.168.0.1
SSH_PASS="${SSH_PASS:-12345}"

ping -c 3 -W 2 $CAM > /dev/null 2>&1 || { echo "cam_linkmode: no camera at $CAM"; exit 0; }
for try in 1 2; do
	timeout 40 sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-o LogLevel=ERROR -o ConnectTimeout=20 root@$CAM "
		command -v linkmode > /dev/null || { echo 'cam_linkmode: camera has no linkmode'; exit 0; }
		[ \"\$(cat /tmp/link_mode 2>/dev/null)\" = $TARGET ] && { echo 'cam_linkmode: camera already $TARGET'; exit 0; }
		linkmode $TARGET -n || exit 3
		(setsid sh -c 'sleep 2; reboot' > /dev/null 2>&1 < /dev/null &)
		echo 'cam_linkmode: camera reboots into $TARGET'" && exit 0
	echo "cam_linkmode: try $try failed (rc $?)"
	sleep 3
done
echo "cam_linkmode: camera at $CAM did not take $TARGET - not switching"
exit 1
