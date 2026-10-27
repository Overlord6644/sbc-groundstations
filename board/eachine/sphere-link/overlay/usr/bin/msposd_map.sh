#!/bin/sh
# Goggles control of the moving map (ground msposd), for the menu's Actions
# and the buttons: msposd re-reads msposd.ini when it changes. Same size and
# transparency steps as pcpilot's map toolbar.
#   msposd_map.sh toggle | bigger | smaller | zoomin | zoomout | opacity | follow
INI=/usr/bin/msposd.ini

get() { sed -n "s/^$1 *= *//p" $INI | head -1; }
put() {   # set key=value in [map], appending it when missing
	if grep -q "^$1 *=" $INI; then
		sed -i "s|^$1 *=.*|$1 = $2|" $INI
	else
		sed -i "/^\[map\]/a $1 = $2" $INI
	fi
}
say() { /usr/bin/osdmsg "Map: $*"; echo "Map: $*"; }

# sizes: S M L XL full (index 0..4), as width/height percent
size_of() {
	[ "$(get layout)" = "full" ] && { echo 4; return; }
	case "$(get width)" in
		18%) echo 0 ;; 36%) echo 2 ;; 50%) echo 3 ;; *) echo 1 ;;
	esac
}
set_size() {
	case "$1" in
		0) W=18% H=20% N=S ;;  1) W=26% H=28% N=M ;;  2) W=36% H=40% N=L ;;
		3) W=50% H=55% N=XL ;; *) put layout full; say "full screen"; return ;;
	esac
	put layout corner; put width $W; put height $H
	say "size $N"
}

case "$1" in
	toggle)
		if [ "$(get show_on_start)" = "1" ]; then put show_on_start 0; say hidden
		else put show_on_start 1; say shown; fi
		;;
	bigger)  s=$(size_of); [ $s -lt 4 ] && s=$((s + 1)); set_size $s ;;
	smaller) s=$(size_of); [ $s -gt 0 ] && s=$((s - 1)); set_size $s ;;
	zoomin|zoomout)          # zoom on the craft, 10..18 (the pack's levels win)
		z=$(get zoom); [ -n "$z" ] || z=15
		if [ "$1" = zoomin ]; then [ $z -lt 18 ] && z=$((z + 1))
		else [ $z -gt 10 ] && z=$((z - 1)); fi
		put zoom $z; say "zoom $z"
		;;
	opacity)
		case "$(get opacity)" in
			80) o=60 ;; 60) o=40 ;; 40) o=100 ;; *) o=80 ;;
		esac
		put opacity $o; say "transparency $((100 - o))%"
		;;
	follow)
		case "$(get follow)" in
			north) f=plane ;; plane) f=fit ;; fit) f=center ;; *) f=north ;;
		esac
		put follow $f; say "follow $f"
		;;
	*) echo "usage: $0 toggle|bigger|smaller|zoomin|zoomout|opacity|follow"; exit 1 ;;
esac
