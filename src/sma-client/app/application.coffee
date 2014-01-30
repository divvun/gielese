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

  enable_webfonts: () ->
    if not WebFont?
      console.log "ERROR: WebFont async loader not available."
      return
    WebFont.load
      google:
        families: ['Open Sans', 'Kaushan Script']

  switch_locale: (locale, options = {}) ->
    conv_l = ISOs.three_to_two locale
    if conv_l != locale
      locale = conv_l
    $.get "/data/translations/#{locale}/messages.json",
      (locale_data) =>
        gettext = new Gettext({
          domain: 'messages'
          locale_data: locale_data
        })
        @gettext = gettext
        window.gettext = @gettext
        @loadingTracker.markReady('translations.json')
        options.complete() if options.complete

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
    
  soundEffects:
    'click': () => app.playAudio('/static/audio/click.mp3')
    'correct': () => app.soundEffectCorrect()
    'incorrect': () =>  app.soundEffectIncorrect()
    
  playAudio: (path, opts={}) ->
    # TODO: user feedback about whether audio is downloaded or not.
    
    if opts.finished
      finished_event = opts.finished
    else
      finished_event = () -> return false

    has_audio_file = path
    if has_audio_file and soundManager.enabled
      sound_id = "concept_audio"

      # Have to have different behavior for html5-only, because of iOS
      # limitations
      if soundManager.html5Only
        sound_obj = soundManager.getSoundById(sound_id)
        # grab sound obj if it hasn't been created yet
        if not sound_obj
          sound_obj = soundManager.createSound
            id: sound_id
            url: has_audio_file
            onfinish: finished_event
          sound_obj._a.playbackRate = opts.rate
        if sound_obj.url == has_audio_file
          console.log "repeat"
        else
          console.log "no repeat"
          sound_obj.url = has_audio_file

        sound_obj.play({position:0})
      else
        soundManager.destroySound(sound_id)
        s = soundManager.createSound({
          id: sound_id
          url: has_audio_file
          onfinish: finished_event
        })
        s.play()
      return s

    if opts.finished
      opts.finished()
    else
      return false

  constructor: ->
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

  initialize: (options = {}) ->

    # TODO: when to automatically clear localstorage, and check for
    # existing session?
    # TODO: device detection
    @device_type = "mobile"
    @media_size = "small"

    # TODO: modernizr, check for preferred video format, fallback - gif?
    #
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

    @gettext = new Gettext({
      domain: 'messages'
    })
    window.gettext = @gettext

    @auth = new Authenticator()

    @tests = new Tests()

    @conceptdb = new ConceptDB()
    @conceptdb.fetch
      success: () =>
        window.fetched_somewhere = true
        app.loadingTracker.markReady('concepts.json')
        console.log "fetched concepts.json (#{app.conceptdb.models.length})"

    @categories = new CategoryList()
    @categories.fetch
      success: () =>
        window.fetched_somewhere = true
        app.loadingTracker.markReady('categories.json')
        console.log "fetched categories.json (#{app.conceptdb.models.length})"

    @questiondb = new QuestionDB()

    @userprogression = new UserProgression()
    @leksaOptions = new LeksaOptions()

    @router = new Router()

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

    @options = new UserSettings()
    @options.setSettings({
      'interface_language': ISOs.two_to_three initial_language
      'help_language': ISOs.two_to_three initial_language
    })

makeLogger = () ->
  log = log4javascript.getLogger()
  ajaxlogger = new log4javascript.AjaxAppender('/client_logger/')
  log.addAppender(ajaxlogger)
  return log

window.app = new Application
window.client_log = makeLogger()

window.onerror = (errorMsg, url, lineNumber) ->
  window.client_log.fatal(
    "Uncaught error #{errorMsg} in #{url}, line #{lineNumber}"
  )
