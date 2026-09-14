#!/bin/bash
# Rebuild only the pixelpilot package of the runcam_wifilink image from WSL:
#   bash build_pixelpilot_wsl.sh
#
# Buildroot refuses a PATH with spaces (WSL inherits the Windows PATH via
# interop, full of "Program Files"). Force a clean POSIX PATH for the build.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -e
cd "$(dirname "$0")"
OUT="$(pwd)/output/runcam_wifilink_defconfig"
nice make -C buildroot O="$OUT" BR2_EXTERNAL="$(pwd)" pixelpilot
