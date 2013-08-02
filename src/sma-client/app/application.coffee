# TODO: clean up all this.
Router = require 'routers/router'

Authenticator = require 'auth/authentication'

CategoryMenu = require 'views/category_view'
CategoryGames = require 'views/category_games_view'

FrontPage = require 'views/front_page'

LeksaView = require 'views/leksa_view'
LeksaOptionsView = require 'views/leksa_options_view'
UserSettings = require 'models/user_settings'

ErrorView = require 'views/error_view'
GlobalOptionsView = require 'views/global_options'
ConceptList = require 'views/concept_list'
ConceptView = require 'views/concept_view'

LoadingView = require 'views/loading'

ConceptDB = require 'models/conceptdb'
QuestionDB = require 'models/questiondb'
Question = require 'models/question'
Internationalisations = require 'models/internationaliser'
# sample_concepts = require 'sample_data/sample_concepts'

UserProgression = require 'models/user_progression'
AppCacheStatus = require 'views/templates/app_cache_status'
LoadingTracker = require 'loadingtracker'

require 'backbone.offline'

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

          if window.app.options['enable_cache']?
            initWindowCache()

  initialize: (options = {}) ->

    # TODO: device detection
    @device_type = "mobile"

    @loadingTracker = new LoadingTracker()
    @loadingTracker.showLoading()

    @gettext = new Gettext({
      domain: 'messages'
    })
    window.gettext = @gettext

    initial_language = navigator.language || navigator.userLanguage || "no"

    @auth = new Authenticator()

    @options = new UserSettings()
    @options.setDefaults({
      'enable_cache': false
      'enable_audio': true
      'interface_language': 'no'
      'help_language': 'no'
    })

    @conceptdb = new ConceptDB()
    @questiondb = new QuestionDB()

    @leksaUserProgression = new UserProgression()
    @leksaOptions = new LeksaOptions()

    @router = new Router()
    @categoryMenu = new CategoryMenu()
    @categoryGames = new CategoryGames()

    @frontPage = new FrontPage()
    @leksaView = new LeksaView()
    @leksaOptionsView = new LeksaOptionsView()
    @errorView = new ErrorView()
    @globalOptionsView = new GlobalOptionsView()

    @conceptList = new ConceptList()

    @conceptView = new ConceptView

    @loadingView = new LoadingView()

    soundManager.setup
      url: "/static/client/swf/"
      debugMode: false
      useConsole: true
      preferFlash: false
      useHTML5Audio: true
      useFlashBlock: true
      onready: () ->
        console.log "SoundManager ready"

    if initial_language not in ["sma", "se", "no", "en"]
      initial_language = "no"

    $.get( "/data/translations/#{initial_language}/messages.json", (locale_data) =>
      gettext = new Gettext({
        domain: 'messages'
        locale_data: locale_data
      })
      @gettext = gettext
      window.gettext = @gettext
      @loadingTracker.markReady('translations.json')
      @loadingTracker.markReady('internationalisations.json')
      options.complete() if options.complete
    )

window.app = new Application
