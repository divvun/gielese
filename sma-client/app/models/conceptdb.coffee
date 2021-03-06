Concept = require 'models/concept'

module.exports = class ConceptDB extends Backbone.Collection
  model: Concept
  idAttribute: "c_id"

  url: () ->
    if app.server.offline_media
      return "data/concepts.json"
    return app.server.path + "/data/concepts.json"

  initialize: () ->
    @fetch_tries = 0
    # @storage = new Offline.Storage('concepts', @)
    # if navigator.onLine
    #   @storage.sync.pull
    #     success: () =>
    #       app.loadingTracker.markReady('concepts.json')
    #       console.log "fetched concepts.json (#{app.conceptdb.models.length})"
    @fetch
      success: () =>
        window.fetched_somewhere = true
        app.loadingTracker.markReady('concepts.json')
        console.log "fetched concepts.json (#{app.conceptdb.models.length})"
        app.conceptdb.offline = false
      error: () ->
        if app.debug
          console.log "Error reading concepts.json"
        @fetch_tries += 1
        app.conceptdb.offline = true
        if @fetch_tries < 3
          @fetch()
        else
          console.log "Tried fetching concepts.json too many times"
  
  getByCid: (cid) ->
    ms = @models.filter (m) =>
      m.cid == cid

    if ms.length > 0
      ms[0]
    else
      false

  whereSemantics: (sets, extra_filter) ->
    # Really the only reliable way to check the type of an object...
    #
    _type = Object.prototype.toString.call(sets)
    _type_str = Object.prototype.toString.call("str")
    if _type == _type_str
      sets = [sets]

    filtered = @models.filter (m) =>
      sem_match = _.intersection( m.get('semantics')
                                , sets
                                )
      sem_match.length > 0
    result_collection = new ConceptDB()
    result_collection.add filtered

    if extra_filter
      more_filtered = result_collection.where(extra_filter)
      more_collection = new ConceptDB()
      more_collection.add more_filtered
      return more_collection
    return result_collection

  titleImages: (semantic_set) ->
    concepts = @where({'semantics': [semantic_set]})
                     .filter (concept) -> concept.hasThumbnail()

    if concepts.length > 0
      images = concepts[0].hasThumbnail()
      return images

    return false

  where: (params) ->
    # TODO: features
    if 'semantics' of params
      new_coll = @whereSemantics(params.semantics)
      delete params.semantics
      if Object.keys(params).length > 0
        return new_coll.where(params)
      else
        return new_coll.models

    super

  getTranslationsOf: (concept) ->
    @models.filter (comp_concept) =>
      if _.contains( concept.get('translations')
                   , comp_concept.get('id')
                   )
        return true
      else
        return false
