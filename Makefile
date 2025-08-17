# Makefile for Purplecord
TARGET := iphone:clang:2.0:2.0
INSTALL_TARGET_PROCESSES = Purplecord
ARCHS = armv6

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Purplecord

# NOTE: Clang might have ABI incompatibilities so ideally I'd find some GCC patches instead!
#
# Hack: Disable the error where libstdc++ headers can't be found.  I'm providing them here:
HACK = \
	-Wno-error=stdlibcxx-not-found \
	-Wno-stdlibcxx-not-found \
	-I$(THEOS)/sdks/iPhoneOS2.0.sdk/usr/include/c++/4.0.0 \
	-I$(THEOS)/sdks/iPhoneOS2.0.sdk/usr/include/c++/4.0.0/arm-apple-darwin8

Purplecord_FILES = \
	src/iphone/main.m \
	src/iphone/AppDelegate.m \
	src/iphone/GuildListController.m \
	src/iphone/ChannelListController.m \
	src/iphone/ChannelController.m \
	src/iphone/CPPTest.cpp

Purplecord_FRAMEWORKS = UIKit CoreGraphics
Purplecord_CFLAGS = -fno-objc-arc $(HACK)

include $(THEOS_MAKE_PATH)/application.mk
