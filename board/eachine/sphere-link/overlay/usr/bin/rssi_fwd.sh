#!/bin/sh
# Gadget-mode RSSI forwarder. Reads the dongle's two RF-chain percentages
# from the Realtek driver (the real air-link RSSI) and pushes them to the
# PC HUD (:12346, "RSSI a b") and to the camera's aalink feedback
# (:12345, "<worst>,vrx"), ~2 Hz. Started by /usr/sbin/gadget on link up.
PC=192.168.5.100
CAM=192.168.0.1
IF=$(ls /sys/class/net 2>/dev/null | grep '^wlx' | head -n1)
[ -z "$IF" ] && exit 0
D=$(ls -d /proc/net/rtl*/"$IF" 2>/dev/null | head -n1)
[ -z "$D" ] && exit 0

while true; do
	L=$(grep 'rssi_a' "$D/trx_info_debug" 2>/dev/null | head -n1)
	A=$(echo "$L" | grep -o 'rssi_a *= *[0-9]*' | grep -o '[0-9][0-9]*' | head -n1)
	B=$(echo "$L" | grep -o 'rssi_b *= *[0-9]*' | grep -o '[0-9][0-9]*' | head -n1)
	[ -z "$A" ] && A=-1
	[ -z "$B" ] && B=-1
	echo "RSSI $A $B" | socat -u - UDP-SENDTO:$PC:12346 2>/dev/null
	W=$A
	if [ "$B" -ge 0 ] 2>/dev/null && [ "$B" -lt "$W" ] 2>/dev/null; then W=$B; fi
	if [ "$W" -ge 0 ] 2>/dev/null; then
		echo "$W,vrx" | socat -u - UDP-SENDTO:$CAM:12345 2>/dev/null
	fi
	sleep 0.5
done
