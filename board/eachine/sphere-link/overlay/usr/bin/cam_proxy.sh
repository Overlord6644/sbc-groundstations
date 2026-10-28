#!/bin/sh
# Gadget-mode camera proxy. The PC behind the USB gadget cannot reach the
# camera: this image has no iptables, so the VRX does not NAT 192.168.5.0/24
# into the camera's AP, and the camera has no route back to the PC. pcpilot
# talks to the camera through here instead, on the gadget address:
#
#   192.168.5.1:8081  -> camera :80     HTTP API (/api/v1, /request/idr);
#                                        :80 on the VRX is the DVR web UI
#   192.168.5.1:12355 -> camera :12355  command daemon (channel, video mode)
#   192.168.5.1:11223 -> camera :11223  UDP IDR tokens, ACKs relayed back
#
# Started by /usr/sbin/gadget on link up, stopped on teardown.
# busybox here has no pkill: kill by command-line match
killf() {
	for p in $(ps w | grep -F -- "$1" | grep -v -e grep -e awk | awk '{print $1}'); do
		[ "$p" != "$$" ] && kill "$p" 2>/dev/null
	done
}

GS=192.168.5.1
# the camera: its AP address in APFPV, the far end of the wfb-ng tunnel in WFB
# (rx_mode wfb). link_glue.sh restarts this script when the mode changes.
CAM=192.168.0.1
. /etc/default/wifibroadcast 2>/dev/null
[ "$WIFIBROADCAST_ENABLED" = true ] && CAM=10.5.0.10

# only this script's own listeners: rssi_fwd.sh has one on $GS too (12347)
killf "LISTEN:8081,bind=$GS"
killf "LISTEN:12355,bind=$GS"
killf "UDP-LISTEN:11223,bind=$GS"
killf "LISTEN:12356,bind=$GS"

socat TCP-LISTEN:8081,bind=$GS,reuseaddr,fork TCP:$CAM:80 &
socat TCP-LISTEN:12355,bind=$GS,reuseaddr,fork TCP:$CAM:12355 &
# one child per PC socket; -T reaps a child once its peer goes quiet
socat -T 60 UDP-LISTEN:11223,bind=$GS,reuseaddr,fork UDP:$CAM:11223 &
# pcpilot's menu into this VRX's gsmenu.sh: rx_mode and the WFB-NG page
# (gs_remote.sh keeps to that list)
socat TCP-LISTEN:12356,bind=$GS,reuseaddr,fork EXEC:/usr/bin/gs_remote.sh &
wait
