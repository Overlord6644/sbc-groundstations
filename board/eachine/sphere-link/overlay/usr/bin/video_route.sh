#!/bin/sh
# video_route.sh - where the WFB video goes: always to PixelPilot on
# 127.0.0.1, which decodes it for HDMI and restreams it to the PC (as in
# APFPV).
#
# It used to send it straight to the PC while the gadget was up (2026-10-30),
# measured to lose less. That measurement was taken with 3894 B packets,
# which the USB link (MTU 1500) splits in three: the PC path tore, the
# PixelPilot path on HDMI was clean (2026-10-31). The direct path is off;
# PC_DIRECT=1 in /etc/default/video_route brings it back.
#
# Run by link_glue.sh (boot, every rx_mode change) and by gadget (link up
# and down). wfb-server is restarted only when the destination changes.
CFG=/etc/wifibroadcast.cfg
PC=192.168.5.100

. /etc/default/wifibroadcast 2>/dev/null
. /etc/default/video_route 2>/dev/null
if [ "$PC_DIRECT" = 1 ] && [ "$WIFIBROADCAST_ENABLED" = true ] && [ -d /sys/kernel/config/usb_gadget/g1 ]; then
	dest=$PC
else
	dest=127.0.0.1
fi

cur=$(sed -n "/^\[gs_video\]/,/^\[/ s|^peer = 'connect://\([0-9.]*\):5600'.*|\1|p" $CFG)
if [ "$cur" != "$dest" ]; then
	sed -i "/^\[gs_video\]/,/^\[/ s|^peer = .*|peer = 'connect://$dest:5600'  # video_route.sh|" $CFG
	sync
	if [ "$WIFIBROADCAST_ENABLED" = true ]; then
		setsid /etc/init.d/S98wifibroadcast restart < /dev/null > /dev/null 2>&1 &
	fi
	echo "video_route: WFB video to $dest"
fi

# the ground msposd draws for the goggles only: off while the PC shows it
if [ "$dest" = "$PC" ]; then
	killall -q -STOP msposd
else
	killall -q -CONT msposd
fi
