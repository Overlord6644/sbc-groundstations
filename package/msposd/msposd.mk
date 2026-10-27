###############################################################################
#
# msposd
#
###############################################################################

MSPOSD_VERSION = 9bca2c37b5fb9eb13eac1bac1e2b7192b6fa95d5
# Fork: the moving map on a goggles without DisplayPort from the FC (redraw on
# attitude, show_on_start, live msposd.ini), pixel OSD and MAVLink work. Builds for Rockchip
# without X11 straight from the sources below, so no Makefile patch.
MSPOSD_SITE = https://github.com/Overlord6644/msposd.git
MSPOSD_SITE_METHOD = git
MSPOSD_INSTALL_TARGET = YES
MSPOSD_DEPENDENCIES = cairo libevent sqlite host-pkgconf

define MSPOSD_INSTALL_TARGET_CMDS

	$(INSTALL) -m 755 -t $(TARGET_DIR)/usr/bin $(@D)/msposd
	$(INSTALL) -m 755 -t $(TARGET_DIR)/etc/init.d $(MSPOSD_PKGDIR)/files/S98msposd

	mkdir -p $(TARGET_DIR)/etc/default
	$(INSTALL) -m 755 -t $(TARGET_DIR)/etc/default $(MSPOSD_PKGDIR)/files/msposd

	mkdir -p $(TARGET_DIR)/usr/share/fonts
	
	$(INSTALL) -m 755 $(@D)/fonts/original/betaflight/font_hd.png $(TARGET_DIR)/usr/share/fonts/font_hd.png
	$(INSTALL) -m 755 $(@D)/fonts/original/betaflight/font.png $(TARGET_DIR)/usr/share/fonts/font.png

	$(INSTALL) -m 755 $(@D)/fonts/font_ardu_hd.png $(TARGET_DIR)/usr/share/fonts/font_ardu_hd.png
	$(INSTALL) -m 755 $(@D)/fonts/font_ardu.png $(TARGET_DIR)/usr/share/fonts/font_ardu.png

	$(INSTALL) -m 755 $(@D)/fonts/original/betaflight/font_hd.png  $(TARGET_DIR)/usr/share/fonts/font_btfl_hd.png
	$(INSTALL) -m 755 $(@D)/fonts/original/betaflight/font.png $(TARGET_DIR)/usr/share/fonts/font_btfl.png

	$(INSTALL) -m 755 $(@D)/fonts/original/inav/font_hd.png $(TARGET_DIR)/usr/share/fonts/font_inav_hd.png
	$(INSTALL) -m 755 $(@D)/fonts/original/inav/font.png $(TARGET_DIR)/usr/share/fonts/font_inav.png

endef

define MSPOSD_BUILD_CMDS
	echo '#define GIT_VERSION "$(MSPOSD_VERSION)"' > $(@D)/version.h
	cd $(@D) && $(TARGET_CC) $(TARGET_CFLAGS) \
		$$(sed -n 's/^SRCS := //p' Makefile) $$(sed -n 's/^GS_SRCS := //p' Makefile) \
		-I. -Isdk/gk7205v300/include \
		$$($(PKG_CONFIG_HOST_BINARY) --cflags cairo sqlite3 libevent_core) \
		-D__ROCKCHIP__ -Wno-address-of-packed-member -Wno-incompatible-pointer-types \
		-DVERSION_STRING='"$(MSPOSD_VERSION)"' -O2 \
		$(TARGET_LDFLAGS) \
		$$($(PKG_CONFIG_HOST_BINARY) --libs cairo sqlite3 libevent_core) -lm -lrt \
		-o msposd
endef

$(eval $(generic-package))