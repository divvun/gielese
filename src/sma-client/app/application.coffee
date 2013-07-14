Router = require 'routers/router'
CategoryMenu = require 'views/category_view'

CategoryGames = require 'views/category_games_view'

FrontPage = require 'views/front_page'

LeksaView = require 'views/leksa_view'
LeksaOptionsView = require 'views/leksa_options_view'

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

#    Backbone.offline allows your Backbone.js app to work offline
#    https://github.com/Ask11/backbone.offline
#
#    (c) 2012 - Aleksey Kulikov
#    May be freely distributed according to MIT license.

do (global = window, _, Backbone) ->
  global.Offline =
    VERSION: '0.4.3'

    # This is a method for CRUD operations with localStorage.
    # Delegates to 'Offline.Storage' and works as ‘Backbone.sync’ alternative
    localSync: (method, model, options, store) ->
      resp = switch(method)
        when 'read'
          if _.isUndefined(model.id) then store.findAll(options) else store.find(model, options)
        when 'create' then store.create(model, options)
        when 'update' then store.update(model, options)
        when 'delete' then store.destroy(model, options)

      if resp
        options.success(model, resp.attributes ? resp, options)
      else
        options.error?('Record not found')

    # Overrides default 'Backbone.sync'. It checks 'storage' property of the model or collection
    # and then delegates to 'Offline.localSync' when property exists else calls the default 'Backbone.sync' with received params.
    sync: (method, model, options) ->
      store = model.storage || model.collection?.storage
      if store and store?.support
        Offline.localSync(method, model, options, store)
      else
        Backbone.ajaxSync(method, model, options)

    onLine: ->
      navigator.onLine isnt false

  # Override 'Backbone.sync' to default to 'Offline.sync'
  # the original 'Backbone.sync' is available in 'Backbone.ajaxSync'
  Backbone.ajaxSync = Backbone.sync
  Backbone.sync = Offline.sync

  # This class is use as a wrapper for manipulations with localStorage
  # It's based on a great library https://github.com/jeromegn/Backbone.localStorage
  # with some specific methods.
  #
  # Create your collection of this type:
  #
  # class Dreams extends Backbone.Collection
  #   initialize: ->
  #     @storage = new Offline.Storage('dreams', this)
  #
  # After that your collection will work offline.
  #
  # Instance attributes:
  # @name - storage name
  # @sync - instance of Offline.Sync
  # @allIds - index of ids for the collection
  # @destroyIds - index for destroyed models
  class Offline.Storage

    # Name of storage and collection link are required params
    constructor: (@name, @collection, options = {}) ->
      @support = @isLocalStorageSupport()
      @allIds = new Offline.Index(@name, this)
      @destroyIds = new Offline.Index("#{@name}-destroy", this)
      @sync = new Offline.Sync(@collection, this)
      @keys = options.keys || {}
      @autoPush = options.autoPush || false

    # Test from modernizr: https://github.com/Modernizr/Modernizr/blob/master/modernizr.js
    # Normally, we could not test that directly and need to do a
    #   `('localStorage' in window) && ` test first because otherwise Firefox will
    #   throw bugzil.la/365772 if cookies are disabled
    #
    # Also in iOS5 Private Browsing mode, attempting to use localStorage.setItem
    # will throw the exception:
    #   QUOTA_EXCEEDED_ERRROR DOM Exception 22.
    # Peculiarly, getItem and removeItem calls do not throw.
    isLocalStorageSupport: ->
      try
        localStorage.setItem('isLocalStorageSupport', '1')
        localStorage.removeItem('isLocalStorageSupport')
        true
      catch e
        false

    # Most implementations of HTML5 localStorage have a size limit of about 5MB.
    # When data starts exceeding this limit, setting a key value throws the QUOTA_EXCEEDED_ERROR.
    # in other cases localSync support will be stopped
    setItem: (key, value) ->
      try
        localStorage.setItem key, value
      catch e
        if e.name is 'QUOTA_EXCEEDED_ERR'
          @collection.trigger('quota_exceed')
        else
          @support = false

    # Wrappers for localStorage methods
    removeItem: (key) ->
      localStorage.removeItem(key)

    getItem: (key)->
      localStorage.getItem(key)

    # Add a model, giving it a unique GUID. Server id saving to "sid".
    # Set a sync's attributes updated_at, dirty and add
    create: (model, options = {}) ->
      options.regenerateId = true
      @save(model, options)

    # Update a model into the set. Set a sync's attributes update_at and dirty.
    update: (model, options = {}) ->
      @save(model, options)

    # Delete a model from the storage
    destroy: (model, options = {}) ->
      @destroyIds.add(sid) unless options.local or (sid = model.get('sid')) is 'new'
      @remove(model, options)

    find: (model, options = {}) ->
      JSON.parse @getItem("#{@name}-#{model.id}")

    # Returns the array of all models currently in the storage.
    # And refreshes the storage into background
    findAll: (options = {}) ->
      unless options.local
        if @isEmpty() then @sync.full(options) else @sync.incremental(options)
      JSON.parse(@getItem("#{@name}-#{id}")) for id in @allIds.values

    s4: ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1)

    incrementId: 0x1000000
    localId1: ((1+ Math.random()) * 0x100000 | 0).toString(16).substring(1)
    localId2: ((1+ Math.random()) * 0x100000 | 0).toString(16).substring(1)

    mid: ->
       ((new Date).getTime()/1000 | 0).toString(16) + @localId1 + @localId2 + (++@incrementId).toString(16).substring(1)

    guid: ->
      @s4() + @s4() + '-' + @s4() + '-' + @s4() + '-' + @s4() + '-' + @s4() + @s4() + @s4()

    save: (item, options = {}) ->
      if options.regenerateId
        id = if options.id is 'mid' then @mid() else @guid()
        item.set(sid: item.attributes?.sid || item.attributes?.id || 'new', id: id)
      item.set(updated_at: (new Date()).toJSON(), dirty: true) unless options.local

      @replaceKeyFields(item, 'local')
      @setItem "#{@name}-#{item.id}", JSON.stringify(item)
      @allIds.add(item.id)

      @sync.pushItem(item) if @autoPush and !options.local
      item

    remove: (item, options = {}) ->
      @removeItem "#{@name}-#{item.id}"
      @allIds.remove(item.id)

      sid = item.get('sid')
      @sync.flushItem(sid) if @autoPush and sid isnt 'new' and !options.local

      item

    isEmpty: ->
      @getItem(@name) is null

    # Clears the current storage
    clear: ->
      keys = Object.keys(localStorage)
      collectionKeys = _.filter keys, (key) => (new RegExp @name).test(key)
      @removeItem(key) for key in collectionKeys
      record.reset() for record in [@allIds, @destroyIds]

    # Replaces local-keys to server-keys based on options.keys.
    replaceKeyFields: (item, method) ->
      if Offline.onLine()
        item = item.attributes if item.attributes

        for field, collection of @keys
          replacedField = item[field]

          if !/^\w{8}-\w{4}-\w{4}/.test(replacedField) or method isnt 'local'
            newValue = if method is 'local'
              wrapper = new Offline.Collection(collection)
              wrapper.get(replacedField)?.id
            else
              collection.get(replacedField)?.get('sid')
            item[field] = newValue unless _.isUndefined(newValue)
      item

  # Sync collection with a server. All server requests delegated to 'Backbone.sync'
  # It provides a backward-compability. If your application is working with 'Backbone.sync'
  # it'll be working with a 'Offline.sync'
  #
  # @storage = new Offline.Storage('dreams', this)
  # @storage.sync - access to class instance through Offline.Storage
  class Offline.Sync
    constructor: (collection, storage) ->
      @collection = new Offline.Collection(collection)
      @storage = storage

    ajax: (method, model, options) ->
      if Offline.onLine()
        @prepareOptions(options)
        # TODO: ajax response seems to be returning a string which success:
        # functions don't know what to do with-- but I don't want to believe
        # yet that the problem is here...
        #
        # NOTE: problem is compatibility difference between Backbone 1.0 and
        # 0.9.10; which has some API changes to success and error callbacks.
        # 
        # https://github.com/jashkenas/backbone/commit/6e646f1ba
        #
        res = Backbone.ajaxSync(method, model, options)
        return res
      else
        @storage.setItem('offline', 'true')

    # @storage.sync.full() - full storage synchronization
    # 1. clear collection and store
    # 2. load new data
    full: (options = {}) ->
      @ajax 'read', @collection.items, _.extend {}, options,
        success: (model, response, opts) =>
          @storage.clear()
          @collection.items.reset([], silent: true)
          @collection.items.create(item, silent: true, local: true, regenerateId: true) for item in response
          @collection.items.trigger('reset') unless options.silent
          options.success(model, response, opts) if options.success

    # @storage.sync.incremental() - incremental storage synchronization
    # 1. pull() - request data from server
    # 2. push() - send modified data to server
    incremental:(options = {}) ->
      @pull _.extend {}, options, success: => @push()

    # Runs incremental sync when storage was offline
    # after current request therefore don't duplicate requests
    prepareOptions: (options) ->
      if @storage.getItem('offline')
        @storage.removeItem('offline')
        success = options.success
        options.success = (model, response, opts) =>
          success(model, response, opts)
          @incremental()

    # Requests data from the server and merges it with a collection.
    # It's useful when you want to refresh your collection and don't want to reload it completely.
    # If response does not include any local ids they will be removed
    # Local data will be compared with a server's response using updated_at field and new objects will be created
    #
    # @storage.sync.pull()
    pull: (options = {}) ->
      @ajax 'read', @collection.items, _.extend {}, options,
        success: (model, response, opts) =>
          @collection.destroyDiff(response)
          @pullItem(item) for item in response
          options.success(model, response, opts) if options.success

    pullItem: (item) ->
      local = @collection.get(item.id)
      if local
        @updateItem(item, local)
      else
        @createItem(item)

    createItem: (item) ->
      unless _.include(@storage.destroyIds.values, item.id.toString())
        item.sid = item.id
        delete item.id
        @collection.items.create(item, local: true)

    updateItem: (item, model) ->
      if (new Date(model.get 'updated_at')) < (new Date(item.updated_at))
        delete item.id
        model.save(item, local: true)

    # Use to send modifyed data to the server
    # You can use it manually for sending changes
    #
    # @storage.sync.push()
    #
    # At first, method gets all dirty-objects (added or updated)
    # and sends every object to server using 'Backbone.sync' method
    # after that it sends deleted objects to the server
    push: ->
      @pushItem(item) for item in @collection.dirty()
      @flushItem(sid) for sid in @storage.destroyIds.values

    pushItem: (item) ->
      @storage.replaceKeyFields(item, 'server')
      localId = item.id
      delete item.attributes.id
      [method, item.id] = if item.get('sid') is 'new' then ['create', null] else ['update', item.attributes.sid]

      @ajax method, item, success: (model, response, opts) =>
        item.set(sid: response.id) if method is 'create'
        item.save {dirty: false}, {local: true}

      item.attributes.id = localId; item.id = localId

    flushItem: (sid) ->
      model = @collection.fakeModel(sid)
      @ajax 'delete', model, success: (model, response, opts) =>
        @storage.destroyIds.remove(sid)

  # Manage indexes storing to localStorage.
  # For example 1,2,3,4,5,6
  class Offline.Index

    # @name - index name
    # @storage.setItem 'dreams', '1,2,3,4'
    # records = new Offline.Index('dreams', @storage)
    # records.values - an array based on @storage data
    # => ['1', '2', '3', '4']
    constructor: (@name, @storage) ->
      store = @storage.getItem(@name)
      @values = (store && store.split(',')) || []

    # Add a new item to the end of list
    # records.add '5'
    # records.values
    # => ['1', '2', '3', '4', '5']
    add: (itemId) ->
      unless _.include(@values, itemId.toString())
        @values.push itemId.toString()
      @save()

    # Remove element from a list of values
    # records.remove '3'
    # records.values
    # => ['1', '2', '4', '5']
    remove: (itemId) ->
      @values = _.without @values, itemId.toString()
      @save()

    save: ->
      @storage.setItem @name, @values.join(',')

    reset: ->
      @values = []
      @storage.removeItem @name

  # Uses as wrapper for 'Backbone.Collection'
  class Offline.Collection

    # @items is an instance of 'Backbone.Collection'
    constructor: (@items) ->

    # Returns models marked as "dirty" - {dirty: true}
    # That is needy for synchronization with server
    dirty: ->
      @items.where dirty: true

    # Get a model from the set by sid.
    get: (sid) ->
      @items.find (item) -> item.get('sid') is sid

    # destory old models from the collection which have not marked as "new"
    destroyDiff: (response) ->
      diff = _.difference(_.without(@items.pluck('sid'), 'new'), _.pluck(response, 'id'))
      @get(sid)?.destroy(local: true) for sid in diff

    # Use to create a fake model for the set
    fakeModel: (sid) ->
      model = new Backbone.Model(id: sid)
      model.urlRoot = @items.url
      model

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

window.i18n = new Internationalisations()

fakeGetText = (string) ->
  ### Want to mark strings as requiring gettext somehow, so that
      a babel can find them.

      NB: Babel only has a javascript extractor, so, just compile to JS first

      Then when you run pybabel's extract command, it will find the
      strings in the unminified source.

      # TODO: storage format for internationalisations on media_serv
      #
      Internationalizations are downloaded and stored in localStorage
      on the first run of the plugin. Translations should degrade to
      english if they are missing, or the localization is not present.

      The system will not store multiple localizations at a time, so
      we assume the user does not really want to switch.
  ###
  
  if window.i18n?
  	console.log "has i18n"
  	if window.i18n.ready
  	  console.log "is ready"
  	  return window.i18n.fakeGetText(string)

  return string

# NB: using underscore as the function name conflicts with underscore.js
#

window.fakeGetText = fakeGetText

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
      console.log "you are online"

    window.addEventListener "offline", (e) ->
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

    @internationalisations = window.i18n

    @loadingTracker = new LoadingTracker()
    @loadingTracker.showLoading()

    default_options = {
      'enable_cache': false
      'enable_audio': true
    }

    @options = DSt.get('app_options') || default_options
    @options.interface_lang = 'no'
    @options.help_lang = 'no'

    @conceptdb = new ConceptDB()
    @questiondb = new QuestionDB()

    # moved to collection.initialize for convenience
    @conceptdb.storage = new Offline.Storage('concepts', @conceptdb)
    @conceptdb.storage.sync.pull()
    # @conceptdb.fetch
    #   success: () =>
    #     app.loadingTracker.markReady('concepts.json')
    #     console.log "fetched concepts.json (#{app.conceptdb.models.length})"

    @questiondb.fetch
      success: () =>
        app.loadingTracker.markReady('leksa_questions.json')
        console.log "fetched leksa_questions.json (#{app.questiondb.models.length})"
        

    @internationalisations.fetch
      success: () =>
        app.loadingTracker.markReady('internationalisations.json')
        console.log "fetched internationalisations.json (#{app.internationalisations.models.length})"

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
