class ConceptView extends Backbone.View

  play: (evt) ->
    @model.playAudio()
    return false

  nextConcept: (evt) ->
    console.log "next"
    console.log @next
    # app.conceptList.nextConcept(@next)
    return false

  template: require './templates/concept_item'

  render: ->
    lang = app.options.getSetting('help_language')

    if not lang
      lang = "nob"

    fallback = false
    translations = @model.getTranslationsToLang lang
    txl_string = (a.get('concept_value') for a in translations).join(', ')

    if translations.length == 0
      console.log "no translations found for #{lang}, defaulting..."
      translations = @model.getTranslationsToLang "nob"
      fallback = true

    console.log [@next, @prev]

    @$el.html @template({
      model: @model
      cid: @model.cid
      concept_value: @model.get('concept_value')
      concept_type: @model.get('concept_type')
      translations: translations
      txl_string: txl_string
      fallback: fallback
      userlang: lang
      next: @next
      prev: @prev
    })

    this

module.exports = class ConceptList extends Backbone.View

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    'click .concept_link': 'showConcept'
    'click #cycle-concept-prev': 'prevConcept'
    'click #cycle-concept-next': 'nextConcept'
  
  clickTest: (evt) ->
    $(evt.target).get
    console.log evt
    return true

  nextConcept: ->
    if @next?
      # TODO: what to do when end arrives?
      @conceptByIndex(@next)
    return false

  prevConcept: ->
    if @prev?
      @conceptByIndex(@prev)
    return false

  conceptByIndex: (concept_index) ->
    concept = @concepts_in_order[concept_index]

    prev = null
    if (concept_index - 1) > -1
      prev = concept_index - 1

    next = concept_index + 1

    concept_template = new ConceptView {
      model: concept
    }

    @current_concept_view = concept_template

    @prev = prev
    @next = next

    $('#concept_content').html concept_template.render().$el.html()
    $('#concept_content').trigger('create')

    return false

  showConcept: (evt) ->
    concept_index = parseInt $(evt.target).attr('data-concept-index')
    console.log concept_index

    concept = @concepts_in_order[concept_index]

    prev = null
    if (concept_index - 1) > -1
      prev = concept_index - 1

    next = concept_index + 1


    concept_template = new ConceptView {
      model: concept
    }

    @current_concept_view = concept_template

    @prev = prev
    @next = next

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
    @current_concept_view.play()
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
    category_concepts = _.sortBy category_concepts,
      (c) -> c.get('concept_value')

    initial = new ConceptView {
      model: category_concepts[0]
    }

    @current_concept_view = initial

    @next = 1
    @prev = null

    @concepts_in_order = category_concepts

    @$el.html @template {
      category: @for_category
      models: category_concepts
      initial_model: initial.render().$el.html()
    }

    this
