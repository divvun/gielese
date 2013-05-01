Concept = require 'models/concept'

module.exports = class ConceptDB extends Backbone.Collection
  model: Concept
  url: "/data/concepts.json"

  getTranslationsOf: (concept) ->
    @models.filter (comp_concept) =>
      if _.contains( concept.get('translations')
                   , comp_concept.get('c_id')
                   )
        return true
      else
        return false

