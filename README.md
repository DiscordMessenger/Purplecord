# Purplecord

This is an attempt to create a Discord client for iOS 2 and 3.

Support for newer versions of iOS is not guaranteed because I do not own any newer devices.

This can log in (which takes about 50 seconds on my iPhone 3G over Wi-Fi), view messages,
and send simple messages. But it is not fully featured yet! And also, it's really slow and
drains your battery fast, so probably not very practical either.

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

### Building MbedTLS

First, clone the repository.
```
git clone https://github.com/DiscordMessenger/mbedtls
```

Then, build it:
```
mkdir build && cd build
cmake .. \
	-DCMAKE_TOOLCHAIN_FILE=../iphoneos.cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DENABLE_TESTING=OFF \
	-DENABLE_PROGRAMS=OFF \
	-DCMAKE_INSTALL_PREFIX=$CD/../install
make -j$(nproc)
```

Define the environment variable related to this:
```
PURPLECORD_MBEDTLS_PATH=[your mbedtls checkout path]
```

### Building Libcurl

After building OpenSSL you will need to build libcurl too.

Download:
```
curl -LO https://curl.se/download/curl-7.88.1.tar.gz
tar xf curl-7.88.1.tar.gz
cd curl-7.88.1
```

Then open `lib/vtls/mbed.tls` and move this line:
```c
  mbedtls_ssl_conf_rng(&backend->config, mbedtls_ctr_drbg_random,
                       &backend->ctr_drbg);
```
to between `mbedtls_ssl_init` and `mbedtls_ssl_setup`.

Then configure and make:
```bash
cmake .. -DCMAKE_TOOLCHAIN_FILE=../iphoneos.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$CD/../install \
  -DCURL_USE_MBEDTLS=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_CURL_EXE=OFF \
  -DCURL_STATICLIB=ON \
  -DMBEDTLS_INCLUDE_DIRS=$PURPLECORD_MBEDTLS_PATH/include \
  -DMBEDTLS_LIBRARY=$PURPLECORD_MBEDTLS_PATH/build/library/libmbedtls.a \
  -DMBEDX509_LIBRARY=$PURPLECORD_MBEDTLS_PATH/build/library/libmbedx509.a \
  -DMBEDCRYPTO_LIBRARY=$PURPLECORD_MBEDTLS_PATH/build/library/libmbedcrypto.a \
  -DCURL_DISABLE_FTP=ON \
  -DCURL_DISABLE_FILE=ON \
  -DCURL_DISABLE_LDAP=ON \
  -DCURL_DISABLE_LDAPS=ON \
  -DCURL_DISABLE_RTSP=ON \
  -DCURL_DISABLE_DICT=ON \
  -DCURL_DISABLE_TELNET=ON \
  -DCURL_DISABLE_TFTP=ON \
  -DCURL_DISABLE_POP3=ON \
  -DCURL_DISABLE_IMAP=ON \
  -DCURL_DISABLE_SMTP=ON \
  -DCURL_DISABLE_GOPHER=ON \
  -DCURL_DISABLE_MQTT=ON \
  -DCURL_DISABLE_SMB=ON \
  -DCURL_DISABLE_NTLM=ON \
  -DENABLE_WEBSOCKETS=ON

make -j$(nproc)
```

NOTE: If you get an error that says `SystemFramework was not found`, edit CMakeLists.txt and remove the dependency on SystemFramework as we don't have it.


Define the environment variables:
```
PURPLECORD_LIBCURL_PATH=[your curl checkout path]
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
