# Purplecord

This is an attempt to create a Discord client for iOS 2 and 3.

Support for newer versions of iOS is not guaranteed because I do not own any newer devices.

This does nothing currently!

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

TBD

### Fetching the iPhoneOS 2.0 SDK

You don't need to use the iPhoneOS 2.0 sdk.  I'll add the iPhoneOS 3.0 SDK soon.

I used the following archive name, which can be found on the Internet Archive:
iphone_sdk_for_iphone_os_2.2.19m2621afinal.dmg

Extract this image, go to `iPhone SDK/Packages` and extract `iPhoneSDK2_0.pkg` (I used 7-Zip to
extract), and then extract the `Payload~` into `$THEOS/sdks/` inside with `cpio -i < Payload~`.

Then, in `$THEOS/sdks`, make a symlink to the `iPhoneOS2.0.sdk` folder inside `Platforms/iPhoneOS.platform/Developer/SDKs` like this:
```
ln -s Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk iPhoneOS2.0.sdk
```

Make sure you are in the `$THEOS/sdks` folder.

### Making OpenSSL

Just like [Discord Messenger](https://github.com/DiscordMessenger/dm), you will need to build OpenSSL.

Apply the diff at `opensslpatch.diff` in the checked out OpenSSL repository with the following command:

```bash
git apply [purplecord repo]/opensslpatch.diff
```

Then, configure OpenSSL and compile with the following commands:
```
perl ./Configure iphoneos-cross-custom no-shared no-asm no-tests --openssldir=./output/opensslapple/armv6 CROSS_COMPILE=$THEOS/toolchain/linux/iphone/bin/ "CC=clang -target armv6-apple-darwin9 -isysroot $THEOS/sdks/iPhoneOS3.0.sdk" -DBROKEN_CLANG_ATOMICS
make -j$(nproc) build_sw
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
