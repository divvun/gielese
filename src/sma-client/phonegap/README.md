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

## Major TODOs:

 * Phonegap media paths must be within the phonegap server thingy, but when
   running standalone, they need to instead be coming from the media server.

 * Audio playing: No need for Soundmanager to handle this, use test on
   phonegap's device API

# Installing

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
    cordova emulate android

This appears to also build the project before launching. Rerunning will
update the emulator.

## Add plugins

    cordova plugin add org.apache.cordova.media
    cordova plugin add org.apache.cordova.inappbrowser

## Updating cordova, etc.

When updates come from Cordova, there are some steps to follow. For the
purposes of Gïelese, I'll attempt to keep things at version@3.3.0.

 * [Updating Cordova, etc.][updating]

  [updating]: http://docs.phonegap.com/en/3.3.0/guide_cli_index.md.html#The%20Command-Line%20Interface

