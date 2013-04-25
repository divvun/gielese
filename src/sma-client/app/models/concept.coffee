
module.exports = class Concept extends Backbone.Model
  # attributes: { language: false # string (3char)
  #             , concept_type: false # string (3char)
  #             , concept_value: # string (word, url)
  #             , semantics: [ ] # list
  #             , features: [ ] # list
  #             , c_id: null # int
  #             , translations: [ ] # list of related ints
  #             }
  render_concept: () ->
    concept_renderers =
      'img': (c) ->
        return "<img class='concept img_concept' src='#{c.get('concept_value')}' />"
      'text': (c) ->
        return "<span class='concept word_concept'>#{c.get('concept_value')}</span>"
    type = @.get('concept_type')
    return concept_renderers[type](@)


