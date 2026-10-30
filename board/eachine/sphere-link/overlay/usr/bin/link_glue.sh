#!/bin/sh
# Ground-side plumbing that depends on the link mode (rx_mode), so the camera
# is reached where it is: 192.168.0.1 on its access point in APFPV,
# 10.5.0.10 at the far end of the wfb-ng tunnel in WFB. Run at boot
# (S99link_glue) and by gsmenu.sh after every rx_mode change.
#
#  - WFB: PixelPilot sends its keyframe tokens to the video's last hop, which
#    in WFB is 127.0.0.1 (wfb_rx hands it the stream): relayed here to the
#    camera's keyframe listener (gslink -i, :11223), ACKs relayed back.
#  - gadget mode: the PC's camera proxy (cam_proxy.sh) picks the camera's
#    address when it starts, so it is restarted on a mode change.

# busybox here has no pkill: kill by command-line match
killf() {
	for p in $(ps w | grep -F -- "$1" | grep -v -e grep -e awk | awk '{print $1}'); do
		[ "$p" != "$$" ] && kill "$p" 2>/dev/null
	done
}

. /etc/default/wifibroadcast 2>/dev/null

killf "UDP-LISTEN:11223,bind=127.0.0.1"
if [ "$WIFIBROADCAST_ENABLED" = true ]; then
	setsid socat -T 60 UDP-LISTEN:11223,bind=127.0.0.1,reuseaddr,fork UDP:10.5.0.10:11223 \
		> /dev/null 2>&1 < /dev/null &
fi

if ps w | grep -v grep | grep -q cam_proxy.sh; then
	killf cam_proxy.sh      # its socats go with its next start (killf bind=)
	setsid /usr/bin/cam_proxy.sh > /dev/null 2>&1 < /dev/null &
fi
# the PC HUD's RSSI source follows the mode too (driver in APFPV, wfb-server
# in WFB): rssi_fwd.sh decides at start. "rssi_fwd" matches both the shell
# script and wfb_rssi_fwd.py, which it becomes in WFB.
if ps w | grep -v grep | grep -q rssi_fwd; then
	killf rssi_fwd; killf "UDP-RECV:12347"
	setsid /usr/bin/rssi_fwd.sh > /dev/null 2>&1 < /dev/null &
fi
# PixelPilot's link-warning glow: one widget per mode, and only this mode's
# on. The APFPV one reads the station RSSI, which reads 0 in WFB (no station):
# left on, it lit the whole frame red at LQ 100 %. "---" disables a widget.
OSDJ=/etc/pixelpilot/osd.json
if [ -f $OSDJ ]; then
	[ "$WIFIBROADCAST_ENABLED" = true ] && off=SignalWarning on=SignalWarningWfb \
		|| { off=SignalWarningWfb; on=SignalWarning; }
	awk -v off="$off" -v on="$on" '
		/"name": *"/ { n = $0; sub(/.*"name": *"/, "", n); sub(/".*/, "", n) }
		/"type": *"(---)?SignalWarningWidget"/ {
			if (n == off) sub(/"(---)?SignalWarningWidget"/, "\"---SignalWarningWidget\"")
			if (n == on)  sub(/"(---)?SignalWarningWidget"/, "\"SignalWarningWidget\"")
		}
		{ print }' $OSDJ > /tmp/osd.json.new
	if ! cmp -s $OSDJ /tmp/osd.json.new; then
		cat /tmp/osd.json.new > $OSDJ; sync
		# SIGTERM ends pixelpilot.sh's loop too (rc 143): start it again
		if killall -q pixelpilot; then
			sleep 1
			setsid /etc/init.d/S99pixelpilot start < /dev/null > /dev/null 2>&1
		fi
	fi
	rm -f /tmp/osd.json.new
fi
# where the WFB video goes: straight to the PC while it is on the gadget
/usr/bin/video_route.sh
echo "link_glue: $([ "$WIFIBROADCAST_ENABLED" = true ] && echo wfb || echo apfpv)"
