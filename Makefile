# Makefile for Purplecord
TARGET := iphone:clang:3.0:3.0
TARGET_CC := clang-22
TARGET_CXX := clang-22
TARGET_LD := $(THEOS)/toolchain/linux/iphone/bin/clang++ -v
INSTALL_TARGET_PROCESSES = Purplecord
ARCHS = armv6

PURPLECORD_MBEDTLS_PATH ?= /mnt/c/DiscordMessenger/mbedtls-apple
PURPLECORD_LIBCURL_PATH ?= /mnt/c/DiscordMessenger/libcurl-apple

# It is not recommended to build with debug mode.
#FINALPACKAGE ?= 1

ifeq ($(FINALPACKAGE),1)
	DEBUGSW = -DNDEBUG
else
	DEBUGSW = -D_DEBUG
endif

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
	-I$(PURPLECORD_MBEDTLS_PATH)/include \
	-I$(PURPLECORD_LIBCURL_PATH)/include \
	-fno-tree-vectorize \
	-fno-vectorize

# NOTE: -Wl,-w hides incompat warnings for now ...
LDHACKS = \
	-L$(THEOS)/libcxx-hack/usr/lib \
	-L$(PURPLECORD_MBEDTLS_PATH)/build/library \
	-L$(PURPLECORD_LIBCURL_PATH)/build/lib \
	-lc++ \
	-lc++abi \
	-lmbedtls \
	-lmbedx509 \
	-lmbedcrypto \
	-lcurl \
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
	src/iphone/NetworkController.mm \
	src/iphone/Frontend_iOS.mm \
	src/iphone/TextInterface_iOS.cpp \
	src/iphone/HTTPClient_curl.cpp \
	src/iphone/WebsocketClient_curl.cpp \
	src/iphone/MessageItem.mm \
	src/iphone/MessageInputView.mm \
	src/iphone/UIColorScheme.mm \
	src/iphone/ImageLoader.mm \
	src/iphone/AvatarCache.mm

Purplecord_FRAMEWORKS = UIKit CoreGraphics
Purplecord_CFLAGS = -fno-objc-arc $(INCLUDES) $(CPPHACKS) $(WARNINGDISABLES) $(SWITCHES)
Purplecord_LDFLAGS = $(LDHACKS)

include $(THEOS_MAKE_PATH)/application.mk
