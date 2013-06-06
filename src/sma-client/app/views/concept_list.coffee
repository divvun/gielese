class UpdatingConceptView extends Backbone.View
  template: require './templates/concept_item'

  render: ->
    lang = switch app.options.help_lang
            when "no" then "nob"
            when "sv" then "swe"
            else app.options.help_lang

    @$el.html @template({
      model: @model
      cid: @model.cid
      concept_value: @model.get('concept_value')
      concept_type: @model.get('concept_type')
      translations: @model.getTranslationsToLang lang
    })

    this

module.exports = class ConceptList extends Backbone.View

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    # 'click ul.ui-listview a': 'clickTest'
  
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
    console.log event.target
    concept_id = $(event.target)
                  .attr('data-concept-cid')

    concept = app.conceptdb.getByCid concept_id
    if concept
      sound_id = "wordListSound"
      concept.playAudio(sound_id)
    return false

  className: 'conceptlist'

  template: require './templates/concept_list'

  render: ->

    @_conceptViews = []
    if @for_category
      semantics = [@for_category]

    console.log semantics
    filtered_collection = app.conceptdb.where({
      'semantics': semantics
      'language': 'sma'
    })

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
      @$el.find('#concept_list_view').append(_el)

    this
