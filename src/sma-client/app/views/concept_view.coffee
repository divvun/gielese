module.exports = class ConceptView extends Backbone.View

  events:
    'click a.audio_link': 'play'

  id: 'conceptview'

  template: require './templates/concept_view'

  play: (evt) ->
    @model.playAudio()
    return false

  initialize: (id) ->
    super
    @model = app.conceptdb.getByCid(id)
    console.log "omg init"
    console.log @model

  render: ->

    @$el.html @template {
      model: @model
      translations: app.conceptdb.getTranslationsOf @model
    }

    this

