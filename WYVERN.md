# This fork, for the EMAX Wyvern stack

Integration branch: `eachine-sphere-link`, on top of OpenIPC/sbc-groundstations
`master` (`upstream` remote; level with it on 2026-10-28). It adds the
**Eachine Sphere Link** VRX board and what the Wyvern stack needs on it.

## What it adds, and where

| Area | Where |
|---|---|
| Board profile, boot files (LF only: a CRLF in `extlinux.conf` hung the boot) | `board/eachine/sphere-link/`, `configs/eachine_sphere-link_defconfig`, `.gitattributes` |
| USB gadget to a PC: auto when no HDMI, left long-press toggles it, stable DHCP | `overlay/usr/sbin/gadget`, init scripts |
| Camera proxy for pcpilot: camera API (:8081), air_man (:12355), keyframe tokens (:11223) | `overlay/usr/bin/cam_proxy.sh` |
| Ground feedback to aalink: best antenna's RSSI, and pcpilot's video loss | `overlay/usr/bin/rssi_fwd.sh` |
| Moving map in the goggles: MSP relay from the camera (to the ground msposd and to the PC), map packs synced from pcpilot, size/transparency/zoom from the menu | `overlay/usr/bin/msp_relay.py`, `msposd_map.sh`, `map_sync.sh`, `msposd.ini` |
| REC button action, restream, headless run | `overlay/usr/bin/rec-toggle.sh`, `pixelpilot.yaml` |
| PixelPilot and msposd from the Wyvern forks, pinned by commit | `package/pixelpilot/pixelpilot.mk`, `package/msposd/msposd.mk` |
| CI builds the Sphere Link image in the board matrix | `.github/workflows/master.yml` |

## Building the image

CI runs on a push to `master` and on tags starting with `2` (CalVer, e.g.
`26.10`); branch pushes do not build. Before tagging, check that the pinned
commits are on GitHub: `git branch -r --contains <pin>` in the fork.
`build_pixelpilot_wsl.sh` rebuilds only the pixelpilot package locally.
