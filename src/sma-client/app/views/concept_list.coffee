class UpdatingConceptView extends Backbone.View
  template: require './templates/concept_item'

  render: ->
    @$el.html @template({
      model: @model
      cid: @model.cid
      concept_value: @model.get('concept_value')
      concept_type: @model.get('concept_type')
      translations: app.conceptdb.getTranslationsOf @model
    })

    this

module.exports = class ConceptList extends Backbone.View

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    'click ul.ui-listview a': 'clickTest'
  
  clickTest: (evt) ->
    $(evt.target).get
    console.log evt
    return true

  # Left panel
  revealOptionsPanel: (evt) ->
    panel_options =
      position: "left"
    $('#word-links').panel('open', panel_options)
    return false

  findAudio: (event) ->
    concept_id = $(event.target)
                  .parent('a.audio_link')
                  .attr('data-concept')

    concept = app.conceptdb.getByCid concept_id
    sound_id = "wordListSound"
    concept.playAudio(sound_id)
    return false

  className: 'conceptlist'

  template: require './templates/concept_list'

  initialize: () ->
    super
    @_conceptViews = []
    #
    # Filter out images, will display these via translations
      
  render: ->

    filtered_collection = @collection.where({
      'language': 'sma'
    }).filter (o) ->
      "BODYPART" in o.get('semantics')

    @$el.html @template {
      models: filtered_collection.map (m) ->
        return {
          model: m
          cid: m.cid
          concept_value: m.get('concept_value')
          concept_type: m.get('concept_type')
          translations: app.conceptdb.getTranslationsOf m
        }
    }

    _(filtered_collection).each (concept) =>
      @_conceptViews.push new UpdatingConceptView({
        model: concept
      })

    _(@_conceptViews).each (cv) =>
      _el = cv.render().$el.html()
      @$el.find('ul[data-role="listview"]').append(_el)

    this
