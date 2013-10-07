ConceptItem = require './templates/item'
ConceptListTemplate = require './templates/list'
ConceptViewMain = require './templates/concepts'

class ConceptView extends Backbone.View

  play: (evt) ->
    @model.playAudio()
    return false

  template: ConceptItem

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

    success = false
    if app.user
      success = @model.successRateInUserLog()
    else
      if app.leksaUserProgression.models.length > 0
        success = @model.successRateInUserLog()

    @$el.html @template({
      model: @model
      success_rate: success
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
  id: "concept_view"
  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealWordsPanel"
    'click .concept_link': 'showConcept'
    'click #cycle-concept-prev': 'prevConcept'
    'click #cycle-concept-next': 'nextConcept'
  
  clickTest: (evt) ->
    $(evt.target).get
    console.log evt
    return true

  nextConcept: ->
    if @next?
      @conceptByIndex(@next)
    return false

  prevConcept: ->
    if @prev?
      @conceptByIndex(@prev)
    return false

  conceptByIndex: (concept_index) ->
    concept = @concepts_in_order[concept_index]
    if not concept
      return false

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

    concept_list = @$el.find('#concept-list')
    concept_link = concept_list.find("[data-concept-index=#{concept_index}]")

    concept_list.find('.ui-btn-active-d').removeClass('ui-btn-active-d')
    concept_link.parents('li.ui-btn').addClass('ui-btn-active-d')

    el_pos = concept_link.parents('li.ui-btn').position()
    link_li = concept_link.parents('li.ui-btn')

    new_position = concept_list.scrollTop(
      concept_list.scrollTop() +
      (link_li.position().top - concept_list.position().top) -
      (concept_list.height()/2) +
      (link_li.height()/2)
    )

    # if link_li.position().top > concept_list.height()
    #   concept_list.animate({
    #     scrollTop: new_position
    #   }, 'slow')

    return false

  showConcept: (evt) ->
    concept_index = parseInt $(evt.target).attr('data-concept-index')

    @$el.find('.ui-btn-active-d').removeClass('ui-btn-active-d')
    $(evt.target).parents('li.ui-btn').addClass('ui-btn-active-d')

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
    $('#wordlist_panel').panel('close', {})
    return false

  findAudio: (event) ->
    @current_concept_view.play()
    return false

  className: 'conceptlist'

  template: ConceptListTemplate

  render: ->

    @_conceptViews = []
    if @for_category
      semantics = [@for_category]

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

    get_success_color = (_float) ->
      _class = ''
      if (1 >= _float) && (_float >= .9)
        _class = 'success-rate-green'
      if (.9 > _float) && (_float > .7)
        _class = 'success-rate-yellow'
      if (.7 > _float) && (_float > .49)
        _class = 'success-rate-orange'
      if (.49 > _float) && (_float > .1)
        _class = 'success-rate-red'
      return _class

    window.get_success_color = get_success_color
    @$el.html @template {
      category: @for_category
      models: category_concepts
      initial_model: initial.render().$el.html()
      get_success_color: get_success_color
    }

    @$el.find('ul#concept-list li:first').addClass('ui-btn-active-d')

    this
