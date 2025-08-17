TARGET := iphone:clang:2.0:2.0
INSTALL_TARGET_PROCESSES = Purplecord
ARCHS = armv6

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Purplecord

Purplecord_FILES = main.m AppDelegate.m GuildListController.m ChannelListController.m ChannelController.m
Purplecord_FRAMEWORKS = UIKit CoreGraphics
Purplecord_CFLAGS = -fno-objc-arc

include $(THEOS_MAKE_PATH)/application.mk
