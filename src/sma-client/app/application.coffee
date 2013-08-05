# Views
Router = require 'routers/router'

# User stuff
Authenticator = require 'auth/authentication'
UserSettings = require 'models/user_settings'
UserProgression = require 'models/user_progression'

# Data
LoadingTracker = require 'loadingtracker'
ConceptDB = require 'models/conceptdb'
QuestionDB = require 'models/questiondb'

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

class LeksaOptions
  constructor: ->

module.exports = class Application

  constructor: ->
    $ =>
      @initialize
      	complete: () =>
          Backbone.history.start
            pushState: false
            hashChange: true
            root: window.location.pathname

          $(document).bind "pagechange", (e, data) ->
            webkit = $.browser.webkit
            not_string = data.toPage isnt "string"
            root_page = data.toPage.attr("data-url") is '/'
            if webkit and not_string and root_page
              app.router.index()
              return e.preventDefault()

          if window.app.options.getSetting('enable_cache')?
            initWindowCache()

  initialize: (options = {}) ->

    # TODO: device detection
    @device_type = "mobile"

    @loadingTracker = new LoadingTracker({
      'concepts.json': false
      'leksa_questions.json': false
      'translations.json': false
    })

    @loadingTracker.showLoading()

    @gettext = new Gettext({
      domain: 'messages'
    })
    window.gettext = @gettext

    @auth = new Authenticator()

    @conceptdb = new ConceptDB()
    @questiondb = new QuestionDB()

    @leksaUserProgression = new UserProgression()
    @leksaOptions = new LeksaOptions()

    @router = new Router()

    soundManager.setup
      url: "/static/client/swf/"
      debugMode: false
      useConsole: true
      preferFlash: false
      useHTML5Audio: true
      useFlashBlock: true
      onready: () ->
        console.log "SoundManager ready"

    # usually ISO 639-1, excepting languages that don't have them but the trick
    # is that we want to store ISO 639-2, because the lexicon has special needs
    initial_language = navigator.language || navigator.userLanguage || "no"

    # Force Norwegian if someone doesn't have one of the localizations
    # supported here.
    if initial_language not in ["sma", "sv", "no"]
      initial_language = "no"

    initial_language = ISOs.three_to_two initial_language

    $.get( "/data/translations/#{initial_language}/messages.json", (locale_data) =>
      gettext = new Gettext({
        domain: 'messages'
        locale_data: locale_data
      })
      @gettext = gettext
      window.gettext = @gettext
      @loadingTracker.markReady('translations.json')
      options.complete() if options.complete
    )

    # Convert the initial ISO settings

    @options = new UserSettings()
    @options.setSettings({
      'interface_language': ISOs.two_to_three initial_language
      'help_language': ISOs.two_to_three initial_language
    })


window.app = new Application
