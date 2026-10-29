#!/bin/sh
# gs_remote.sh - pcpilot's menu reaches this VRX's gsmenu.sh here, so its
# ground and WFB-NG pages are the very ones the goggles use. Served by
# cam_proxy.sh on TCP 192.168.5.1:12356 (gadget mode only). One request line:
#   <get|set|button> <type> <page> <param> [value...]
# Allowed: every ground page (system, DVR, APFPV, WiFi, actions... - the VRX's
# own settings, which the PC menu answered Unknown before) and the air wfbng
# page. Arguments are passed as words, never evaluated.
read -r op type page param rest
case "$op" in get|set|button) ;; *) echo Unknown; exit 0 ;; esac
case "$type $page" in
	"gs "*) ;;
	"air wfbng") ;;
	*) echo Unknown; exit 0 ;;
esac
# the camera where it is now, as the goggles' menu exports it
. /etc/default/wifibroadcast 2>/dev/null
[ "$WIFIBROADCAST_ENABLED" = true ] && REMOTE_IP=10.5.0.10 || REMOTE_IP=192.168.0.1
export REMOTE_IP
if [ "$op $type $param" = "set gs rx_mode" ]; then
	# the switch restarts this very listener (link_glue.sh): run it apart
	setsid /usr/bin/gsmenu.sh set gs system rx_mode $rest < /dev/null > /dev/null 2>&1 &
	echo ok
	exit 0
fi
# shellcheck disable=SC2086 # the value words go through as words
out=$(/usr/bin/gsmenu.sh "$op" "$type" "$page" "$param" $rest)
# gsmenu.sh prints nothing for a set that went through; say so, or the PC
# menu reads silence as Unknown
[ -z "$out" ] && [ "$op" = set ] && out=ok
printf '%s\n' "$out"
