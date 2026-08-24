#!/bin/sh

# Headless (gadget / PC-dongle) support: with no HDMI display attached the
# RK3566 DRM creates no output and pixelpilot cannot start - it needs a
# connector, so it would crash-loop ("cannot initialize display") and never
# restream to the PC. Force any disconnected HDMI connector "connected" so DRM
# exposes a virtual 1080p output; pixelpilot then runs headless and restreams
# over the USB gadget. A real display is left untouched (it already reads
# "connected"). Re-checked on every restart in case the connector is not ready
# yet at first boot.
force_hdmi() {
  for s in /sys/class/drm/card*-HDMI-A-*/status; do
    [ -e "$s" ] || continue
    [ "$(cat "$s" 2>/dev/null)" = disconnected ] && echo on > "$s" 2>/dev/null
  done
}

while true
do
  force_hdmi
  test -r /etc/default/pixelpilot && . /etc/default/pixelpilot
  /usr/bin/pixelpilot $PIXELPILOT_ARGS "$@"
  rc=$?
  if [ $rc = 2 -o $rc = 143 -o $rc = 137 ]
  then
    echo "Pixelpilot exited: $rc, skip restart ...."
    exit 2
  fi
  echo "Pixelpilot exited: $rc, restart ...."
  sleep 1
done
