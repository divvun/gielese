Router = require 'routers/router'
HelloView = require 'views/hello_view'
LeksaView = require 'views/leksa_view'
GlobalOptionsView = require 'views/global_options'
ConceptList = require 'views/concept_list'

ConceptDB = require 'models/conceptdb'
QuestionDB = require 'models/questiondb'
Question = require 'models/question'
# sample_concepts = require 'sample_data/sample_concepts'

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
  if window.applicationCache
    window.applicationCache.onchecking = (e) ->
      console.log "onchecking"
  
    window.applicationCache.onnoupdate = (e) ->
      console.log("No updates")
    
    window.applicationCache.onupdateready = (e) ->
      console.log("Update ready")
    
    window.applicationCache.onobsolete = (e) ->
      console.log("Obsolete")
    
    window.applicationCache.ondownloading = (e) ->
      console.log("Downloading")
    
    window.applicationCache.oncached = (e) ->
      console.log("Cached")
    
    window.applicationCache.onerror = (e) ->
      console.log("Error")
  
    counter = 0
    window.applicationCache.onprogress = (e) ->
      console.log("checking")
      console.log("Progress: downloaded file " + counter)
      counter++
  
    window.addEventListener "online", (e) ->
      console.log "you are online"
  
    window.addEventListener "offline", (e) ->
      console.log "you are offline"

module.exports = class Application

  constructor: ->
    $ =>
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

      # TODO: reenable cache when less changes are going on
      initWindowCache()

  initialize: ->
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

    @router = new Router
    @helloView = new HelloView
    @leksaView = new LeksaView
    @globalOptionsView = new GlobalOptionsView
    @conceptList = new ConceptList({
      collection: @conceptdb
    })
    soundManager.setup({
      url: "/static/client/swf/"
      preferFlash: false
      useHTML5Audio: true
      useFlashBlock: true
      onready: () ->
        console.log "SoundManager ready"
        soundManager.createSound({
          id: "someSound"
          url: "/static/audio/vce1/gaalloe.mp3"
        })
        soundManager.play()
    })
    threeSixtyPlayer.config = {
      playNext: false
      # , // stop after one sound, or play through list until end
      autoPlay: false
      # , // start playing the first sound right away
      allowMultiple: false
      # , // let many sounds play at once (false = one at a time)
      loadRingColor: '#ccc'
      # , // amount of sound which has loaded
      playRingColor: '#000'
      # , // amount of sound which has played
      backgroundRingColor: '#eee'
      # , // "default" color shown underneath everything else
      animDuration: 500
      # ,
      animTransition: Animator.tx.bouncy
      # // http://www.berniecode.com/writing/animator.html
    }


window.app = new Application
