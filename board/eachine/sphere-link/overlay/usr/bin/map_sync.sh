#!/bin/sh
# Copy pcpilot's map packs to the goggles while the PC is on the USB gadget.
# pcpilot fills them around the craft from the web (swisstopo, SWISSIMAGE,
# OpenTopoMap) and lists them on http://192.168.5.100:8091/maps/ as
# "<name> <size> <mtime>". Whatever changed is fetched to a temp name,
# checked against the listed size, then renamed into /root/maps - the ground
# msposd notices the new file and reopens it. Started and stopped by
# /usr/sbin/gadget with the link.
PC=http://192.168.5.100:8091/maps
D=/root/maps
S=$D/.sync
mkdir -p $S

while :; do
	wget -q -T 5 -O /tmp/maps.idx $PC/ 2>/dev/null || { sleep 30; continue; }
	while read -r name size mtime; do
		case "$name" in
			*[!A-Za-z0-9._-]*|.*|"") continue ;;
			*.mbtiles) ;;
			*) continue ;;
		esac
		[ "$(cat $S/$name 2>/dev/null)" = "$size $mtime" ] && continue
		if wget -q -T 60 -O $D/$name.part $PC/$name 2>/dev/null &&
		   [ "$(wc -c < $D/$name.part)" = "$size" ]; then
			mv $D/$name.part $D/$name
			echo "$size $mtime" > $S/$name
			/usr/bin/osdmsg "Map: $name updated from the PC"
		else
			rm -f $D/$name.part   # changed while copying: next round
		fi
	done < /tmp/maps.idx
	sleep 30
done
