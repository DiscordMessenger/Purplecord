# Purplecord

This is an attempt to create a Discord client for iOS 2 and 3.

Support for newer versions of iOS is not guaranteed because I do not own any newer devices.

This does nothing currently!

## Attributions

Thanks to [Electimon](https://yzu.moe) for helping me out with getting C++11 support on such ancient iOS versions!

## Building

You must have [Theos](https://theos.dev/docs/installation) installed.  You cannot use any of the
SDKs Theos provides, so you must find the iPhoneOS 3.0 SDK to build.

Also, building has only been tested on Linux, but it might work on Mac OS too.

### Install Clang 21

You will need Clang 21 to compile this project.  If Clang 21 is not provided by your distro's package
manager, you can install Clang 21 with the following command:
```bash
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 21
```

### Fixing a Theos quirk

An issue has been filed for this: https://github.com/theos/theos/issues/847

Basically the way this is supposed to work is, C/ObjC/C++ files will use your system Clang-21 for linking, but
linking should be done with the linker from Theos.  A temporary fix in `$THEOS/makefiles/instance/rules.mk`:

```diff
-TARGET_CXX = $(TARGET_CXX)
+#TARGET_CXX = $(TARGET_CXX)
```

### Fetching the iPhoneOS 3.0 SDK

Download this archive:

Then extract its contents to `$THEOS/sdks/iPhoneOS3.0.sdk`.

### Installing the libc++ hack

Download this archive:

Extract it to `$THEOS/libcxx-hack`.  It should be picked up by the makefile eventually.

### Building OpenSSL

Just like [Discord Messenger](https://github.com/DiscordMessenger/dm), you will need to build OpenSSL.

Apply the diff at `opensslpatch.diff` in the checked out OpenSSL repository with the following command:

```bash
git apply [purplecord repo]/opensslpatch.diff
```

Then, configure OpenSSL and compile with the following commands:
```
perl ./Configure \
	iphoneos-cross-custom \
	no-shared \
	no-asm \
	no-tests \
	--openssldir=./output/opensslapple/armv6 \
	CROSS_COMPILE=$THEOS/toolchain/linux/iphone/bin/ \
	"CC=clang -target armv6-apple-darwin9 -isysroot $THEOS/sdks/iPhoneOS3.0.sdk" \
	-DBROKEN_CLANG_ATOMICS
make -j$(nproc) build_sw
```

Finally, define the environment variable:
```
OPENSSL_DIR=[your openssl checkout dir]
```

### Building Libcurl

After building OpenSSL you will need to build libcurl too.

```bash
./configure \
	--host=armv6-apple-darwin9 \
	--disable-shared \
	--enable-static \
	--with-openssl \
	--disable-ftp \
	--disable-file \
	--disable-ldap \
	--disable-ldaps \
	--disable-rtsp \
	--disable-dict \
	--disable-telnet \
	--disable-tftp \
	--disable-pop3 \
	--disable-imap \
	--disable-smtp \
	--disable-gopher \
	--disable-mqtt \
	--disable-smb \
	CC="$THEOS/toolchain/linux/iphone/bin/clang" \
	LD="$THEOS/toolchain/linux/iphone/bin/clang" \
	AR="$THEOS/toolchain/linux/iphone/bin/ar" \
	RANLIB="$THEOS/toolchain/linux/iphone/bin/ranlib" \
	CFLAGS="-target armv6-apple-darwin9 -isysroot $THEOS/sdks/iPhoneOS3.0.sdk -I/mnt/c/DiscordMessenger/opensslapple/include" \
	LDFLAGS="-L$THEOS/sdks/iPhoneOS3.0.sdk/usr/lib -L/mnt/c/DiscordMessenger/opensslapple"

make -j$(nproc)
```

Define the environment variables:
```
LIBCURL_DIR=[your curl checkout dir]
```

### Hack to make the linker use static libc++

This might not be necessary if you know how to make iOS use the required dylibs.

Rename/delete the following files inside `[libcxxpath]/usr/lib`: `libc++.dylib libc++abi.dylib`.

### Making the Project

You should now be able to make the project. Type `make`.
If you want to deploy to your iPhone, set `THEOS_DEVICE_IP` environment variable to your iPhone's IP address
and type `make package install`.  You will need to respring if you haven't installed the app before.

### License

This project is licensed under the MIT license.
