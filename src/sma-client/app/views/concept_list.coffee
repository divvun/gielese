class ConceptView extends Backbone.View
  template: require './templates/concept_item'

  render: ->
    lang = app.options.getSetting('help_language')

    if not lang
      lang = "nob"

    fallback = false
    translations = @model.getTranslationsToLang lang
    if translations.length == 0
      console.log "no translations found for #{lang}, defaulting..."
      translations = @model.getTranslationsToLang "nob"
      fallback = true

    @$el.html @template({
      model: @model
      cid: @model.cid
      concept_value: @model.get('concept_value')
      concept_type: @model.get('concept_type')
      translations: translations
      fallback: fallback
      userlang: lang
    })

    this

module.exports = class ConceptList extends Backbone.View

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    'click .concept_link': 'showConcept'
  
  clickTest: (evt) ->
    $(evt.target).get
    console.log evt
    return true

  showConcept: (evt) ->
    _cid = $(evt.target).attr('data-concept-id')
    concept = app.conceptdb.get(_cid)

    concept_template = new ConceptView {
        model: concept
    }

    $('#concept_content').html concept_template.render().$el.html()
    $('#concept_content').trigger('create')

    return false
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

    # TODO: what is south sami alphabetical order?

    category_concepts = filtered_collection
    category_concepts = _.sortBy category_concepts, (concept) -> concept.get('concept_value')

    initial = new ConceptView {
        model: category_concepts[0]
    }

    @$el.html @template {
      category: @for_category
      models: category_concepts
      initial_model: initial.render().$el.html()
    }

    this
