# Purplecord

This is an attempt to create a Discord client for iOS 2 and 3.

Support for newer versions of iOS is not guaranteed because I do not own any newer devices.

This does nothing currently!

## Building

You must have [Theos](https://theos.dev/docs/installation) installed.  You cannot use any of the
SDKs Theos provides, so you must find the iPhoneOS 2.0 SDK to build.

### Fetching the iPhoneOS 2.0 SDK

I used the following archive name, which can be found on the Internet Archive:
iphone_sdk_for_iphone_os_2.2.19m2621afinal.dmg

Extract this image, go to `iPhone SDK/Packages` and extract `iPhoneSDK2_0.pkg` (I used 7-Zip to
extract), and then extract the `Payload~` into `$THEOS/sdks/` inside with `cpio -i < Payload~`.

Then, in `$THEOS/sdks`, make a symlink to the `iPhoneOS2.0.sdk` folder inside `Platforms/iPhoneOS.platform/Developer/SDKs` like this:
```
ln -s Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk iPhoneOS2.0.sdk
```

Make sure you are in the `$THEOS/sdks` folder.

### Making the Project

You should now be able to make the project. Type `make`.
If you want to deploy to your iPhone, set `THEOS_DEVICE_IP` environment variable to your iPhone's IP address
and type `make package install`.  You will need to respring if you haven't installed the app before.

### License

This project is licensed under the MIT license.
