Router = require 'routers/router'
HelloView = require 'views/hello_view'
LeksaView = require 'views/leksa_view'
ConceptList = require 'views/concept_list'

ConceptDB = require 'models/conceptdb'
sample_concepts = require 'sample_data/sample_concepts'


jQuery.fn.cleanWhitespace = ->
  textNodes = @contents().filter(->
    @nodeType is 3 and not /\S/.test(@nodeValue)
  ).remove()
  this

jQuery.fn.htmlClean = ->
  @contents().filter(->
    unless @nodeType is 3
      $(this).htmlClean()
      false
    else
      not /\S/.test(@nodeValue)
  ).remove()
  this

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

# TODO: initialize local cache / manifest thing 
# http://developer.teradata.com/tag/backbone-js-cache-manifest
#
# TODO: example, docs and demo: http://appcachefacts.info/demo/
# TODO: http://appcachefacts.info/peterlubbers-owc4/index.html#2
#
# TODO: developing will be super irritating with updating cache
# manifest, every time there are code changes in the files; appCache
# only seems to check that manifest is updated, not the actual files
# themselves? 

# TODO: switch to http://html5boilerplate.com/ for markup
#
# TODO: how to test on mobile, and what to do when applicationCache is
# not available? is there a javascript fallback of sorts? 

window.initWindowCache = () ->
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
      Backbone.history.start pushState:true
      # $('div[data-role="page"]').live 'pagehide', (event, ui) ->
      #     $(event.currentTarget).remove()
      #
      # TODO: route for app cache manifest, generate automatically.
      # TODO: reenable cache when less changes are going on
      # initWindowCache()


  initialize: ->
    @conceptdb = new ConceptDB(sample_concepts)

    @router = new Router
    @helloView = new HelloView
    @leksaView = new LeksaView
    @conceptList = new ConceptList({
      collection: @conceptdb
    })
    

window.app = new Application
