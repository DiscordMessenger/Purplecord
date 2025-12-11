# Makefile for Purplecord
BUILD_FOR_IOS3 ?= yes

# It is not recommended to build with debug mode.
# However, for development purposes, FINALPACKAGE is 0 by default.
#FINALPACKAGE ?= 1

# Toolchain
TARGET_CC := clang-22
TARGET_CXX := clang-22
TARGET_LD := $(THEOS)/toolchain/linux/iphone/bin/clang++
INSTALL_TARGET_PROCESSES = Purplecord

# This decides what toolchains and includes to use.
ifeq ($(BUILD_FOR_IOS3), yes)
	TARGET := iphone:clang:3.1.3:3.1.3
	ARCHS = armv6
	EXTRA_INCLUDES = \
		-DIPHONE_OS_3 \
		-DBOOST_REGEX_USE_C_LOCALE \
		-stdlib=libc++ \
		-I$(THEOS)/libcxx-hack/usr/include \
		-I$(THEOS)/libcxx-hack/usr/include/c++/v1
	EXTRA_LDFLAGS = \
		-L$(THEOS)/libcxx-hack/usr/lib \
		-lc++ \
		-lc++abi
	BUILD_PATH = build-ios3
else
	TARGET := iphone:clang:6.0:6.0
	ARCHS = armv7
	EXTRA_INCLUDES = \
		-DIPHONE_OS_6 \
		-I$(THEOS)/libcxx-hack-ios6/dest/iphoneos-armv7/libcxx/usr/include \
		-I$(THEOS)/libcxx-hack-ios6/dest/iphoneos-armv7/libcxx/usr/include/c++/v1
	EXTRA_LDFLAGS = \
		-L$(THEOS)/libcxx-hack-ios6/lipo \
		-lc++ \
		-lc++abi \
		-lemutls
	BUILD_PATH = build-ios6
endif

# These paths are for iProgramInCpp's use and probably will not work on your end.
# Make sure to export your replacements for these as environment variables.
PURPLECORD_MBEDTLS_PATH ?= /mnt/c/DiscordMessenger/mbedtls-apple
PURPLECORD_LIBCURL_PATH ?= /mnt/c/DiscordMessenger/libcurl-apple
PURPLECORD_LIBWEBP_PATH ?= /mnt/c/DiscordMessenger/libwebp

ifeq ($(FINALPACKAGE),1)
	DEBUGSW = -DNDEBUG
else
	DEBUGSW = -D_DEBUG
endif

# Build an IPA instead of a DEB.
#PACKAGE_FORMAT ?= ipa

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Purplecord

CPPHACKS = \
	$(EXTRA_INCLUDES) \
	-I$(PURPLECORD_MBEDTLS_PATH)/include \
	-I$(PURPLECORD_LIBCURL_PATH)/include \
	-I$(PURPLECORD_LIBWEBP_PATH)/src \
	-fno-tree-vectorize \
	-fno-vectorize

# NOTE: -Wl,-w hides incompat warnings for now ...
LDHACKS = \
	$(EXTRA_LDFLAGS) \
	-L$(PURPLECORD_MBEDTLS_PATH)/$(BUILD_PATH)/library \
	-L$(PURPLECORD_LIBCURL_PATH)/$(BUILD_PATH)/lib \
	-L$(PURPLECORD_LIBWEBP_PATH)/$(BUILD_PATH) \
	-lmbedtls \
	-lmbedx509 \
	-lmbedcrypto \
	-lcurl \
	-lwebp \
	-Wl,-w

WARNINGDISABLES = \
	-Wno-deprecated-declarations \
	-Wno-deprecated-literal-operator \
	-Wno-inconsistent-missing-override \
	-Wno-reorder-ctor \
	-Wno-unused-variable \
	-Wno-unused-function \
	-Wno-deprecated-non-prototype \
	-Wno-switch
	
SWITCHES = \
	$(DEBUGSW)                    \
	-DMINGW_SPECIFIC_HACKS        \
	-DASIO_STANDALONE             \
	-DASIO_HAS_THREADS            \
	-DASIO_DISABLE_STD_FUTURE     \
	-DASIO_DISABLE_GETADDRINFO    \
	-DASIO_SEPARATE_COMPILATION

INCLUDES = -Ideps -Ideps/asio -Ideps/zlib

Purplecord_FILES = \
	deps/zlib/deflate.c \
	deps/zlib/inflate.c \
	deps/zlib/compress.c \
	deps/zlib/zutil.c \
	deps/zlib/adler32.c \
	deps/zlib/crc32.c \
	deps/zlib/trees.c \
	deps/zlib/inftrees.c \
	deps/zlib/inffast.c \
	deps/md5/MD5.cpp \
	src/discord/Channel.cpp \
	src/discord/DiscordAPI.cpp \
	src/discord/DiscordClientConfig.cpp \
	src/discord/DiscordInstance.cpp \
	src/discord/DiscordInstance2.cpp \
	src/discord/Emoji.cpp \
	src/discord/FormattedText.cpp \
	src/discord/Guild.cpp \
	src/discord/HTTPClient.cpp \
	src/discord/LocalSettings.cpp \
	src/discord/Message.cpp \
	src/discord/MessageCache.cpp \
	src/discord/MessagePoll.cpp \
	src/discord/NotificationManager.cpp \
	src/discord/Profile.cpp \
	src/discord/ProfileCache.cpp \
	src/discord/Relationship.cpp \
	src/discord/SettingsManager.cpp \
	src/discord/UpdateChecker.cpp \
	src/discord/UserGuildSettings.cpp \
	src/discord/Util.cpp \
	src/discord/Profiling.cpp \
	src/iphone/main.mm \
	src/iphone/AppDelegate.mm \
	src/iphone/GuildListController.mm \
	src/iphone/GuildController.mm \
	src/iphone/ChannelController.mm \
	src/iphone/LoginPageController.mm \
	src/iphone/SettingsController.mm \
	src/iphone/NetworkController.mm \
	src/iphone/Frontend_iOS.mm \
	src/iphone/TextInterface_iOS.cpp \
	src/iphone/HTTPClient_curl.cpp \
	src/iphone/WebsocketClient_curl.cpp \
	src/iphone/MessageCell.mm \
	src/iphone/MessageInputView.mm \
	src/iphone/UIColorScheme.mm \
	src/iphone/ImageLoader.mm \
	src/iphone/AvatarCache.mm

Purplecord_FRAMEWORKS = UIKit CoreGraphics
Purplecord_CFLAGS = -fno-objc-arc $(INCLUDES) $(CPPHACKS) $(WARNINGDISABLES) $(SWITCHES)
Purplecord_LDFLAGS = $(LDHACKS)

include $(THEOS_MAKE_PATH)/application.mk
