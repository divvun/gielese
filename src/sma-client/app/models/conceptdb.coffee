Concept = require 'models/concept'

module.exports = class ConceptDB extends Backbone.Collection
  model: Concept
  url: "/data/concepts.json"

  fetch: () ->
    super
    app.loadingTracker.markReady('concepts.json')
  
  whereSemantics: (sets, extra_filter) ->
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
                   , comp_concept.get('c_id')
                   )
        return true
      else
        return false

