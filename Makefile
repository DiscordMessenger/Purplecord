# Makefile for Purplecord
TARGET := iphone:clang:3.0:3.0
TARGET_CC := clang-21
TARGET_CXX := clang-21
TARGET_LD := $(THEOS)/toolchain/linux/iphone/bin/clang++ -v
INSTALL_TARGET_PROCESSES = Purplecord
ARCHS = armv6

OPENSSL_INC_DIR ?= /mnt/c/DiscordMessenger/opensslapple/include
OPENSSL_LIB_DIR ?= /mnt/c/DiscordMessenger/opensslapple

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Purplecord

# NOTE: Clang might have ABI incompatibilities so ideally I'd find some GCC patches instead!
#
# Hack: Disable the error where libstdc++ headers can't be found.  I'm providing them here:
CPPHACKS = \
	-target armv6-apple-darwin9 \
	-stdlib=libc++ \
	-I$(THEOS)/sdks/iPhoneOS3.0.sdk/usr/include/c++/4.2.1/$(ARCHS)-apple-darwin9 \
	-I$(THEOS)/libcxx-hack/usr/include \
	-I$(THEOS)/libcxx-hack/usr/include/c++/v1 \
	-I$(OPENSSL_INC_DIR) \
	-fno-tree-vectorize \
	-fno-vectorize

LDHACKS = \
	-L$(THEOS)/libcxx-hack/usr/lib \
	-L$(OPENSSL_LIB_DIR) \
	-lc++ \
	-lc++abi \
	-lcrypto \
	-lssl

WARNINGDISABLES = \
	-Wno-deprecated-declarations \
	-Wno-deprecated-literal-operator \
	-Wno-inconsistent-missing-override \
	-Wno-reorder-ctor \
	-Wno-unused-variable \
	-Wno-unused-function \
	-Wno-switch
	
SWITCHES = \
	-DMINGW_SPECIFIC_HACKS        \
	-DASIO_STANDALONE             \
	-DASIO_DISABLE_IOCP           \
	-DASIO_HAS_THREADS            \
	-DASIO_DISABLE_STD_FUTURE     \
	-DASIO_DISABLE_GETADDRINFO    \
	-DASIO_SEPARATE_COMPILATION

INCLUDES = -Ideps -Ideps/asio

Purplecord_FILES = \
	deps/asio/src/asio.cpp \
	deps/asio/src/asio_ssl.cpp \
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
	src/discord/WebsocketClient.cpp \
	src/iphone/main.m \
	src/iphone/AppDelegate.m \
	src/iphone/GuildListController.m \
	src/iphone/ChannelListController.m \
	src/iphone/ChannelController.m \
	src/iphone/Frontend_iOS.cpp \
	src/iphone/TextInterface_iOS.cpp \
	src/iphone/Stuff.cpp

Purplecord_FRAMEWORKS = UIKit CoreGraphics
Purplecord_CFLAGS = -fno-objc-arc $(INCLUDES) $(CPPHACKS) $(WARNINGDISABLES) $(SWITCHES)
Purplecord_LDFLAGS = $(LDHACKS)

include $(THEOS_MAKE_PATH)/application.mk
