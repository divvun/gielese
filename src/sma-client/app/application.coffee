Router = require 'routers/router'
HelloView = require 'views/hello_view'
LeksaView = require 'views/leksa_view'
ErrorView = require 'views/error_view'
GlobalOptionsView = require 'views/global_options'
ConceptList = require 'views/concept_list'

ConceptDB = require 'models/conceptdb'
QuestionDB = require 'models/questiondb'
Question = require 'models/question'
# sample_concepts = require 'sample_data/sample_concepts'

UserProgression = require 'models/user_progression'

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
      loading = $("""
      <div id="loading_float">
          <img src="/static/client/images/icon_loading_spinner.gif"/>
          <span id="status"><span id="message">Initializing offline cache ... </span> <span id="cache_count">&nbsp;</span>/<span id="cache_total">55</span></span>
      </div>
      """)
      loading.appendTo $('body')
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
      console.log "you are online"
  
    window.addEventListener "offline", (e) ->
      console.log "you are offline"
  else
    fadeOutLoader()



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

      # app.router.changePage(app.helloView)

      # TODO: reenable cache when less changes are going on
      if window.app.options['enable_cache']?
        initWindowCache()

  initialize: ->

    # TODO: loading widget until things are downloaded
    $.mobile.loading('show', {
        text: 'Loading media...',
        textVisible: true,
        theme: 'c',
        html: ""
    })

    default_options = {
      'enable_cache': false
      'enable_audio': true
    }
    @options = DSt.get('app_options') || default_options
    @conceptdb = new ConceptDB()
    @questiondb = new QuestionDB()

    # TODO: depending on how slow this can be, may need to signal to user that
    # we're still waiting for concepts
    $.getJSON '/data/concepts.json', false, (data) =>
      console.log "Fetched #{data.length} concepts from /data/concepts.json"
      @conceptdb.add(data)

    $.getJSON '/data/leksa_questions.json', false, (data) =>
      console.log "Fetched #{data.length} concepts from /data/leksa_questions.json"
      @questiondb.add(data)

    @leksaUserProgression = new UserProgression()
    @router = new Router
    @helloView = new HelloView
    @leksaView = new LeksaView
    @errorView = new ErrorView
    @globalOptionsView = new GlobalOptionsView

    @conceptList = new ConceptList({
      collection: @conceptdb
    })

    soundManager.setup({
      url: "/static/client/swf/"
      useConsole: false
      preferFlash: false
      useHTML5Audio: true
      useFlashBlock: true
      onready: () ->
        console.log "SoundManager ready"
    })

    # threeSixtyPlayer.config = {
    #   playNext: false
    #   # , // stop after one sound, or play through list until end
    #   autoPlay: false
    #   # , // start playing the first sound right away
    #   allowMultiple: false
    #   # , // let many sounds play at once (false = one at a time)
    #   loadRingColor: '#ccc'
    #   # , // amount of sound which has loaded
    #   playRingColor: '#000'
    #   # , // amount of sound which has played
    #   backgroundRingColor: '#eee'
    #   # , // "default" color shown underneath everything else
    #   animDuration: 500
    #   # ,
    #   animTransition: Animator.tx.bouncy
    #   # // http://www.berniecode.com/writing/animator.html
    # }


window.app = new Application
