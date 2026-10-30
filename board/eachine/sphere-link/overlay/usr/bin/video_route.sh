#!/bin/sh
# video_route.sh - where the WFB video goes, and what the VRX does with it.
#
# In WFB with the PC on the USB gadget, wfb_rx sends the stream straight to
# the PC (192.168.5.100:5600, what pcpilot listens on), and the VRX's own
# display work stops: PixelPilot gets no stream to decode, the ground msposd
# (the goggles' moving map) is paused. Measured 2026-10-30 at 1 m: through
# PixelPilot's restream the VRX missed ~115 frames per 20 s for good (its
# USB radio starved while PixelPilot decoded and msposd drew), straight to
# the PC 3-6 - the same radio, the same air. In APFPV, or WFB without a PC
# (goggles alone), everything as before: wfb_rx to PixelPilot on 127.0.0.1.
#
# Run by link_glue.sh (boot, every rx_mode change) and by gadget (link up
# and down). wfb-server is restarted only when the destination changes.
CFG=/etc/wifibroadcast.cfg
PC=192.168.5.100

. /etc/default/wifibroadcast 2>/dev/null
if [ "$WIFIBROADCAST_ENABLED" = true ] && [ -d /sys/kernel/config/usb_gadget/g1 ]; then
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
