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

require 'backbone.offline'

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

window.initWindowCache = () ->
  console.log "Initializing appCache"
  # TODO: need some sort of sync feedback for users
  #
  # Some log handlers for the console
  loadingFloat = () ->
    if $('#loading_float').length == 0
      loading = AppCacheStatus {
      	obj_count: 55
      }
      $('body').append loading
      loading = $('#loading_float')
    else
      loading = $('#loading_float')
    loading.fadeOut(4500)
    return loading

  updateLoadingCount = (count, total) =>
    loader = loadingFloat()
    loader.fadeIn(500)
    _count = loader.find('#cache_count')
    _total = loader.find('#cache_total')
    _count.html(count)
    _total.html(total)
    return true

  incrementLoadingCount = () =>
    loader = loadingFloat()
    _count = loader.find('#cache_count')
    _total = loader.find('#cache_total')

    count = parseInt loader.find('#cache_count').html()
    total = parseInt loader.find('#cache_total').html()

    if isNaN(count) or isNaN(total)
      count = 0
      total = 0

    updateLoadingCount(count + 1, total)

  updateLoadingStatusMessage = (msg) =>
    loader = loadingFloat()
    loader.fadeIn(500)
    _msg = loader.find('#status #message')
    _msg.html(msg)
    return true

  fadeOutLoader = () ->
    loader = loadingFloat().fadeOut(1500)
    return true

  window.updateLoadingCount = updateLoadingCount
  window.incrementLoadingCount = incrementLoadingCount
  window.updateLoadingStatusMessage = updateLoadingStatusMessage
  window.fadeOutLoader = fadeOutLoader

  loadingFloat()

  if window.applicationCache
    window.applicationCache.onchecking = (e) ->
      console.log "onchecking"
      updateLoadingStatusMessage("Checking for new media files.")

    window.applicationCache.onnoupdate = (e) ->
      console.log("No updates")
      updateLoadingStatusMessage("No updates.")
      fadeOutLoader()

    window.applicationCache.onupdateready = (e) ->
      console.log("Update ready")
      updateLoadingStatusMessage("Update finished.")
      fadeOutLoader()

    window.applicationCache.onobsolete = (e) ->
      console.log("Obsolete")

    window.applicationCache.ondownloading = (e) ->
      console.log("Downloading")
      updateLoadingStatusMessage("Downloading ...")

    window.applicationCache.oncached = (e) ->
      console.log("Cached")
      updateLoadingStatusMessage("Offline files downloaded.")
      fadeOutLoader()

    window.applicationCache.onerror = (e) ->
      console.log("Error")
      updateLoadingStatusMessage("Caching error! Error connecting.")

    counter = 0
    window.applicationCache.onprogress = (e) ->
      console.log("checking")
      console.log("Progress: downloaded file " + counter)
      incrementLoadingCount()
      counter++

    window.addEventListener "online", (e) ->
      # TODO: things to do here
      console.log "you are online"

    window.addEventListener "offline", (e) ->
      # TODO: things to do here
      console.log "you are offline"
  else
    fadeOutLoader()

class LoadingTracker
  isReady: () ->
    for name, status of @dependencies
      if not status
      	return false
    console.log "In readiness."
    return true

  checkDeps: () ->
    if @isReady()
      @hideLoading()

  markReady: (name) ->
    @dependencies[name] = true
    @checkDeps()

  hideLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('hide')
      clearInterval(interval)
    ,1)
    return false

  showLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('show', {
        text: 'Loading...',
        textVisible: true,
        theme: 'a',
        html: ""
      })
      clearInterval(interval)
    ,1)
    return false

  constructor: ->
    @dependencies = {
      'concepts.json': false
      'leksa_questions.json': false
      'translations.json': false
    }


class LeksaOptions
  constructor: ->


# TODO: loading widget until things are downloaded

module.exports = class Application

  constructor: ->
    $ =>
      # TODO: need to track tasks required before the user can start using the
      # app, so that once all tasks are complete it disappears.
      @initialize()

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

  initialize: ->

    # TODO: json internationalisation format
    #


    @loadingTracker = new LoadingTracker()
    @loadingTracker.showLoading()

    @gettext = new Gettext({
      domain: 'messages'
    })
    window.gettext = @gettext

    $.get( '/data/translations/sv/messages.json', (locale_data) =>
      gettext = new Gettext({
        domain: 'messages'
        locale_data: locale_data
      })
      @gettext = gettext
      window.gettext = @gettext
      @loadingTracker.markReady('translations.json')
      @loadingTracker.markReady('internationalisations.json')
    )


    @auth = new Authenticator()

    @options = new UserSettings({
      'enable_cache': false
      'enable_audio': true
    })
    @options.set('interface_language', 'no')
    @options.set('help_language', 'no')

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

window.app = new Application
