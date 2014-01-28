# Initializing media server

 * Create a virtualenv, run it and initialize from requirements.txt
 * `python -c "import os ; print os.urandom(24)" > secret_key`
 * `python manage.py init_db`
 * `python manage.py install_media -f ../data/sma_media.xml`
 * `python manage.py append_lexical_data -f ../data/n_smanob_test.xml`

The latter only installs/updates definitions for existing words from the
first step, if you want to just install everything, use:

 * `python manage.py install_lexicon -f ../data/n_smanob.xml`

## Final step

Prepare JSON files.

 * `python manage.py prepare_json`

# Internationalisation

Extracting is a little tricky. Mind the dot at the end, as we need the
current directory too.

    pybabel extract -F babel.cfg -o translations/messages.pot ../sma-client/ .

## initialising translations

    pybabel init -i translations/messages.pot -d translations -l sma
    pybabel init -i translations/messages.pot -d translations -l no
    pybabel init -i translations/messages.pot -d translations -l sv
    etc

## updating

    pybabel extract -F babel.cfg -o translations/messages.pot ../sma-client/ .
    pybabel update -i translations/messages.pot -d translations

## compiling

    pybabel compile -d translations

## Updating from transifex

In order to use the transifex client, you need two things:

 * the gïelese virtual environment enabled
 * a user-specific configuration file for transifex in your own home
   directory: ~/.transifexrc ([docs](txdoc)), otherwise, the
   project-specific configuration is already checked in in 
   `src/media-serv/.tx/config`

 [txdoc]: http://support.transifex.com/customer/portal/articles/1000855-configuring-the-client

### user-specific file: ~/.transifexrc

The short of it is to copy all this, and replace the password. If more
is necessary, refer to docs. Token must be left blank.

    [https://www.transifex.com]
    hostname = https://www.transifex.com
    password = yourpasswordgoeshere!
    token = 
    username = aajegebot

### Basic operations

Once the virtualenv is enabled properly, this should mean that the
transifex command line client is available to use. Typically, all you
should need to be concerned with for fetching new translations is:

    tx pull

A specific language can be specified also: 

    tx pull -l sma
    tx pull --language sma

After updating translation strings in messages.pot, send them to the
server for translators to start working:

    tx push --source

If you have made modifications locally to any of the translation files,
you will need to include the `--translations` flag.

Further documentation on the command line tool's various options is [here](txopts).

  [txopts]: http://support.transifex.com/customer/portal/articles/960804-overview


### Additional docs: 

 * http://support.transifex.com/customer/portal/topics/440187-transifex-client/articles
 * `tx --help`

### Developer notes:

* HTML5 audio troubleshooting: http://creativejs.com/resources/web-audio-api-getting-started/

 * Lots of entertaining BS involving choice in indexeddb and SQL storage:
   backbone.sync
     http://backbonejs.org/docs/backbone.html#section-162

   phonegap has own implementation for devices without local SQL
   storage, which is compatible with spec

     http://docs.phonegap.com/en/1.2.0/phonegap_storage_storage.md.html

   also: http://persistencejs.org/

 * So, needs for offline storage: 
   - storing user progression/details between sessions (trying to solve
     this before something like phonegap comes in) 

   - storing individual exercises and concept data
     ALTERNATIVES:
     - create .js file for static things like concepts and questions, include
       in applicationCache, generate on server for sync, store user data in 
       localStorage

## Video format

So, large video files are too much for the user to download. Thus, we
need to compress things. For now, GIF seems to be a good format, as long
as the output quality is high enough.

[ffmpeg][ffmpeg_version] is great, but less than 2.0 has crappy GIF encoding.

  [ffmpeg_version]: http://superuser.com/questions/556029/how-do-i-convert-a-video-to-gif-using-ffmpeg-with-reasonable-quality

It should be easy to install, but if you're on mac, you probably want to
install it on homebrew, however if 2.0 isn't available by default, run
`brew update` and then install with `brew install ffmpeg --devel --with-theora`.

According to the recipe, it may break some things if they depend on it,
so be advised...

http://mergy.org/2013/01/ffmpeg-compile-and-encode-with-h-264mpeg-4/

 - if h.264 doesn't pan out, switching to ogg theora?
 - WebM also: http://michaelverdi.com/post/2812 ; chrome announced
   they're dropping h.264, but this hasn't happened yet
    
     camendesign.com/code/video_for_everybody/test.html

 - h.264 requires license for commercial use, but what we're doing is
   free.


http://www.htmlgoodies.com/html5/client/how-to-embed-video-using-html5.html
http://binaryjs.com/

### video scratch

#### make animated gif by exploding to frames first

    mkdir frames
    ffmpeg -pix_fmt rgb24 -i test.mov -vf scale=320:-1 -r 4 frames/ffout%03d.png
    convert -delay 28 -loop 0 frames/ffout*.png test.mov.gif

optimization seems not to actually optimize all that much

    convert -layers Optimize test.mov.gif test.min.gif

# html5 h.264 codec

    # This works on iOS and Android...
    ffmpeg -i r_ii_hpestidh.in.mov -preset slow -crf 22 -r 28 -vcodec libx264 -profile:v baseline -level 3.0 -s 320x320 r_ii_hpestidh.min.mp4

Finding the right encoding: iOS supports up to a certain bitrate,
and requires the profile 'baseline' and level '3.0' to be set.

# Ogg



## Media notes

These things need documentation...

 * concept.info
   - attributes

 * concepts.info

 * category.info
   - order_by

