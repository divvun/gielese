# Gielese development with phonegap

Trying to maintain a simple build process for a standalone app on gielese.no,
with simultaneous ability to build android and iOS apps.

 * Brunch build path is in `phonegap/gielese/www/`, things are copied there, thus
   if something with the same name exists in `app/assets/` it could be
   overwritten. 
   
   TODO: make sure this goes as smoothly as possible, and move as much from `www/`
   as possible to `assets/`

 * Building all cordova/PhoneGap stuff must happen in `phonegap/gielese`.

 * All external API calls must not use relative paths.

 * Build brunch first, then build phonegap apps.

## Platform deployment steps: 

 * Media directory needs to be pruned for media formats that aren't necessary,
    eg:

    # For iPhone and Android Phones

    python deploy_media_directory.py copy media \
            static/media \
            ../sma-client/phonegap/gielese/www/static/media \
            --strip-formats=original,orig,medium \
            --keep-orphan-formats

    # For Tablets

    python deploy_media_directory.py copy media \
            static/media \
            ../sma-client/phonegap/gielese/www/static/media \
            --strip-formats=original,orig,small \
            --keep-orphan-formats

 * Default offline JSON data needs to be copied.

    python deploy_media_directory.py copy json \
            data \
            ../sma-client/phonegap/gielese/www/data

 * Media DB install process needs to be run for these differnt platform types
   so that different JSON platforms are available

 * Brunch build process must include --production

    brunch build --production

 * Compress images in media directory (ImageOptim.app for now, will find something cross-platform)

TODO: maybe make a fab process to make this easier
 - include removing of `*.map` files and whatnot


### iOS release process

1.) Get certificates and provisioning profiles in order: https://coderwall.com/p/eceasa/getting-everything-for-building-ios-apps-with-build-phonegap-com

2.) Install profiles and certificates

3.) Open project in XCode and ensure that the team is set for provisioning, for
    this you may have to add your Apple developer account for it to be able to locate the team.

4.) Once that is done, run the following command:

    cordova build ios --device

This should automatically sign the package and build it to: 
    
    platforms/ios/build/device/Gielese.app

NB: while addint the team in the project settings you may think it is logical
to specify the main view of the app, because you may be prompted to do so. *do
not*

### Release process

http://stackoverflow.com/questions/17316910/phonegap-run-from-cli-with-release-and-self-signed-app-requires-me-to-patch-co
https://shazronatadobe.wordpress.com/2014/03/12/xcode-5-1-and-cordova-ios/

#### Building release

    phonegap build android
    cd PATH_TO_RELEASE/platforms/android
    ant release

NB: you will be prompted for the keystore password (twice). This is in priv too.

The file will be generated in `bin`. This should be enough for building Android
.apk files for release, but but if this is not enough see further steps in the following document.

http://stackoverflow.com/questions/17316910/phonegap-run-from-cli-with-release-and-self-signed-app-requires-me-to-patch-co

Other relevant docs:

 * http://developer.android.com/tools/device.html
 * http://developer.android.com/tools/publishing/app-signing.html

NB: before uploading a new release to the android app store, be sure to update the versionCode in the AndroidManifest.xml file.


## Debugging

### Android

Debugging the application within Android is fairly simple, assuming you've
gotten the emulator to work.

First, make sure `AndroidManifest.xml` has the following set in the
`<application />` node:

    android:debuggable="true"

Then build and run the app, and open Chrome, and go to

    about:inspect

When you check `Discover USB Devices`, Chrome will look for the emulator and
allow you to debug.

#### Debugging the build process

    cordova build android

Returns way more info than

    phonegap build android

So, if in doubt, use that.

### iOS

Assuming the emulator works, you should be able to open Safari, and

 * Development -> iPhone Simulator -> index.html

This will open a debugger for the emulator instance.

## Major TODOs:

 * publishing in app store: 
   iOS: ? 

 * building for mobile vs. tablet
       http://developer.android.com/guide/practices/screens_support.html#range
       http://developer.android.com/guide/topics/manifest/compatible-screens-element.html
       http://blog.blundell-apps.com/list-of-android-devices-with-pixel-density-buckets/

   expansion file: 

   http://developer.android.com/google/play/expansion-files.html

 * IOS: status bar
   - setting the settings seems not to have resulted in things workign
     (UIViewControllerBasedStatusBarAppearance, UIStatusBarHidden)

# Installing

NB: make sure this is phonegap 3.3.0 for now.

You must have node and npm installed, then: 

 * `sudo npm install -g phonegap`
 * `sudo npm install -g cordova`

I'd suggest installing globally, just because this is the easiest way to make
sure all things have the necessary permissions and are in the path. It may
otherwise be possible to develop while having everything contained in a local
environment though.

## Some additional things

### iOS-related tools

 * `sudo npm install -g ios-sim`

### Android SDK

The Android SDK takes a little more work to install and get an emulator
working, it's best to run through PhoneGap's own documentation on this, because
it's specific and summarized well enough.

 * [Android Platform Guide][androidinstall]
 
 [androidinstall]: http://docs.phonegap.com/en/3.3.0/guide_platforms_android_index.md.html#Android%20Platform%20Guide

# Working with projects

## New project

    cordova create hello com.example.hello HelloWorld

NB: utf8 is a problem here

## Add platforms
    
    cordova platform add ios
    cordova platform add android

NB: to add iOS, you need XCode and the iOS Emulator, to add Android, you need
the Android SDK, and so on. Expect downloading and installing these things to
take some time. Find a good internet connection, and tea or coffee.

## Build

    cordova build [platform]

Platform is optional, otherwise builds all platforms.

## Test

    cordova emulate ios

This appears to also build the project before launching. Rerunning will
update the emulator.

To specify a specific platform version

    cordova emulate ios --target="iPhone-6"

You can find available images by running the following:

    ./platforms/ios/cordova/lib/list-emulator-images 

iOS troubleshooting:
    https://github.com/phonegap/ios-sim


For android you may need to do things via the following instead

    phonegap run android


## Add plugins

    cordova plugin add org.apache.cordova.device
    cordova plugin add org.apache.cordova.media

This one doesn't work yet: 

    cordova plugin add https://github.com/jota-v/cordova-ios-statusbar.git

## Updating cordova, etc.

When updates come from Cordova, there are some steps to follow. For the
purposes of Gïelese, I'll attempt to keep things at version@3.3.0.

 * [Updating Cordova, etc.][updating]

  [updating]: http://docs.phonegap.com/en/3.3.0/guide_cli_index.md.html#The%20Command-Line%20Interface

