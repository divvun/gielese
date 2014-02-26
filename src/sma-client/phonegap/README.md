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


### Release process

http://stackoverflow.com/questions/17316910/phonegap-run-from-cli-with-release-and-self-signed-app-requires-me-to-patch-co

#### Building release

    phonegap build android
    cd PATH_TO_RELEASE/platforms/android
    ant release

NB: you will be prompted for the keystore password (twice). This is in priv too.

The file will be generated in `bin`. This should be enough for building Android
.apk files for release, but but if this is not enough see further steps in the following document.

http://stackoverflow.com/questions/17316910/phonegap-run-from-cli-with-release-and-self-signed-app-requires-me-to-patch-co

## Major TODOs:

 * publishing in app store: 
   + android
     - debug mode not allowed for upload: 
        http://developer.android.com/tools/device.html
     - must be signed:
        http://developer.android.com/tools/publishing/app-signing.html

    

 * some assets appear to be missing since reorg

 * dev vs. live: using server

 * localStorage -- does it need permissions for phonegap?

 * Offline mode means that user login will need to return a token and session data
   that can be stored, so if user tries to log in in offline mode and has been
   kicked out for some reason, they can continue playing

     - offline works now, but

     - when the browser connects again, need to have a login and sync button appear.
     - maybe: https://github.com/nilbus/Backbone.dualStorage

 * Phonegap media paths must be within the phonegap server thingy, but when
   running standalone, they need to instead be coming from the media server.

    - concepts.json works well with pruned media directories.
    - or does it?

 * Make sure that everything can run without a network connection.

    - TODO: show a message on ti-på-topp if user is offline and scores haven't
      been downloaded yet (but store them in local storage just in case)

    - app works without network connection, unless user wants to authenticate.

    - currently app must phone home to be able to work.

 * Audio playing: No need for Soundmanager to handle this, use test on
   phonegap's device API. for now it seems like soundmanager works just the
   same, but it's probably not ideal.

 * Device and other plugin APIs won't actually be available in iOS simulator? 
   `http://docs.phonegap.com/en/edge/guide_platforms_ios_index.md.html`

    - suggested to use ripple to figure this stuff out. : emulate.phonegap.com

 ? What to do when server has new media, but app hasn't been updated? 

 * google fonts and fontawesome needs to have local cached versions

 * status bar
   - setting the settings seems not to have resulted in things workign
     (UIViewControllerBasedStatusBarAppearance, UIStatusBarHidden)

 * freeze orientation

 * icons 

 * rename app
   - the way phonegap sets things up depends on <widget> <name>, which has to
   	 be changed in a few places, and need to confirm that in changing things,
   	 nothing else is broken

 * cordova splash-screen instead? 

 * contact info

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

