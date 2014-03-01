# Views
Router = require 'routers/router'

# User stuff
Authenticator = require 'auth/authentication'
UserSettings = require 'models/user_settings'
UserProgression = require 'models/user_progression'

# Data
LoadingTracker = require 'loadingtracker'
ConceptDB = require 'models/conceptdb'
CategoryList = require 'models/categorylist'
QuestionDB = require 'models/questiondb'

# Media
AudioPlayer = require 'media/audio_player'

# Tests

Tests = require 'tests/tests'

# some global things that get called
require 'backbone.offline'
require 'language_codes'

window.initWindowCache = require 'appcache'

arrayChunk = (a, s) ->
  x = undefined
  i = 0
  c = -1
  l = a.length
  n = []

  while i < l
    (if (x = i % s) then n[c][x] = a[i] else n[++c] = [a[i]])
    i++
  n

window.arrayChunk = arrayChunk

# Mobile Safari fix
Function::bind = (parent) ->
  f = this
  args = []
  a = 1

  while a < args.length
    args[args.length] = args[a]
    a++

  temp = ->
    f.apply parent, args

  temp

class LeksaOptions
  constructor: ->

module.exports = class Application
  # TODO: override server.path in specific development modes

  enable_webfonts: () ->
    if not WebFont?
      console.log "ERROR: WebFont async loader not available."
      return
    WebFont.load
      google:
        families: ['Open Sans', 'Kaushan Script']

  switch_locale: (locale, options = {}) ->
    if options.offline or app.server.offline_media or window.PhoneGapIndex
      offline = true
      tries = options.tries
    else
      offline = false
      tries = 0

    conv_l = ISOs.three_to_two locale
    if conv_l != locale
      locale = conv_l

    if tries > 3
      console.log "Tried to fetch locale too many times"
      return false

    if offline
      locale_path = "data/translations/#{locale}/messages.json"
    else
      locale_path = app.server.path + "/data/translations/#{locale}/messages.json"
    #
    # TODO: error?
    locale_request = $.getJSON locale_path, (locale_data) =>
      window.app.locale_path = locale_path
      window.app.locale_data = locale_data
      gettext = new Gettext({
        domain: 'messages'
        locale_data: locale_data
      })
      @gettext = gettext
      window.gettext = @gettext
      @loadingTracker.markReady('translations.json')
      options.complete() if options.complete
    locale_request.fail () =>
      tries += 1
      app.switch_locale(locale, {offline: true, tries: tries})

  soundEffectCorrect: () ->
    @correct_concept = _.first @conceptdb.where
      semantics: ["CORRECT"]
      concept_value: "CORRECT"
    if @correct_concept
      @correct_concept.playAudio()
    true

  soundEffectIncorrect: () ->
    @incorrect_concept = _.first @conceptdb.where
      semantics: ["INCORRECT"]
      concept_value: "INCORRECT"
    if @incorrect_concept
      @incorrect_concept.playAudio()
    true
    
  icon_resource_path: (p) ->
    # Take what we get if running in the app
    # otherwise make it non-relative if running in standalone mode
    path_infix = ''
    if not window.PhoneGapIndex
      path_infix = '/static/'
    return path_infix + p

  icons:
    'speaker': () -> app.icon_resource_path "images/speaker.png"
    'aajege_logo': () -> app.icon_resource_path "images/aajege.png"
    'ajax_loader': () -> app.icon_resource_path "images/ajax-loader.gif"

  soundEffects:
    'click': () => app.audio.playPath('static/audio/click.mp3')
    'correct': () => app.soundEffectCorrect()
    'incorrect': () =>  app.soundEffectIncorrect()
    
  constructor: ->
    @server =
      path: "http://localhost:5000"
      offline_media: false

    if window.location.hostname == 'gielese.no'
      @server.path = window.location.origin

    @initPhoneGap()

    $ =>
      @enable_webfonts()
      @initialize
        complete: () =>
          Backbone.history.start
            pushState: false
            hashChange: true
            root: window.location.pathname

          # There be dragons here...
          # Webkit has issues with certain things.
          $(document).bind "pagechange", (e, data) ->
            webkit = $.browser.webkit
            not_string = data.toPage isnt "string"
            root_page = data.toPage.attr("data-url") is '/'
            if webkit and not_string and root_page
              app.router.index()
              return e.preventDefault()

          if app.options.getSetting('enable_cache')?
            initWindowCache()
          
          if window.location.hostname == 'localhost'
            console.log "Appending debug watcher"
            debug_watch = $ "<script />"
            debug_watch.attr('src',"http://localhost:9001/ws")
            debug_watch.appendTo 'head'

  initPhoneGap: () ->
    if not window.PhoneGapIndex?
      window.PhoneGapIndex = false

    # Annoying to have to do it this way, but there's no way to emulate this
    if window.PhoneGapIndex
      if window.plugins?
        if window.plugins.statusBar?
          statusbar = window.plugins.statusBar
          statusbar.hide()
      # This controls where media db is read from.
      @server.offline_media = true
      @server.path = "http://gielese.no"

  initialize: (options = {}) ->
    window.OnlineStatus = true

    # TODO: how to detect phonegap on live device, and choose correct hostname?
    @device_type = "mobile"
    @media_size = "small"
    @video_format = "gif"

    # TODO: when to automatically clear localstorage, and check for
    # existing session?
    @device_type = "mobile"
    @media_size = "small"

    if $(window).width() > 499
      @device_type = "tablet"
      @media_size = "medium"

    @screen_width = $(window).width()
    @screen_height = $(window).height()

    @loadingTracker = new LoadingTracker({
      'concepts.json': false
      'leksa_questions.json': false
      'translations.json': false
      'categories.json': false
    })

    @loadingTracker.showLoading()

    # TODO: use phonegap APIs in AudioPlayer if available.
    @audio = new AudioPlayer()

    @gettext = new Gettext({
      domain: 'messages'
    })
    window.gettext = @gettext

    @auth = new Authenticator()

    @tests = new Tests()

    # These are the media-related collections.
    @conceptdb = new ConceptDB()
    @categories = new CategoryList()
    @questiondb = new QuestionDB()

    # TODO: userprogression should be stored offline using Backbone.Offline
    #       however this needs to be tested obsessively.
    @userprogression = new UserProgression()
    @leksaOptions = new LeksaOptions()

    @router = new Router()

    if not window.PhoneGapIndex
      soundManager.setup
        url: "/static/client/swf/"
        debugMode: false
        defaultOptions:
          volume: 50
        useConsole: true
        preferFlash: false
        useHTML5Audio: true
        useFlashBlock: true
        onready: () ->
          console.log "SoundManager ready"
        ontimeout: () ->
          window.client_log.error('SM2 init failed!')

    # usually ISO 639-1, excepting languages that don't have them but the trick
    # is that we want to store ISO 639-2, because the lexicon has special needs
    initial_language = navigator.language || navigator.userLanguage || "no"

    # Force Norwegian if someone doesn't have one of the localizations
    # supported here.
    if initial_language not in ["sma", "sv", "no"]
      initial_language = "no"

    initial_language = ISOs.three_to_two initial_language

    @switch_locale(initial_language, options)

    # Convert the initial ISO settings

    # TODO: usersettings should be stored offline using Backbone.Offline
    #       however this needs to be tested obsessively.
    @options = new UserSettings()
    @options.setSettings({
      'interface_language': ISOs.two_to_three initial_language
      'help_language': ISOs.two_to_three initial_language
    })

    if window.PhoneGapIndex
      if navigator.splashscreen?
        navigator.splashscreen.show()
        setTimeout(() ->
          navigator.splashscreen.hide()
          window.app.splash()
        , 5000)


makeLogger = () ->
  log = log4javascript.getLogger()
  ajaxlogger = new log4javascript.AjaxAppender(
    window.app.server.path + '/client_logger/'
  )
  ajaxlogger.setWaitForResponse true
  log.addAppender(ajaxlogger)
  return log

window.app = new Application
window.client_log = makeLogger()

window.onerror = (errorMsg, url, lineNumber) ->
  if navigator.onLine
    window.client_log.fatal(
      "Uncaught error #{errorMsg} in #{url}, line #{lineNumber}"
    )
