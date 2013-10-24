ConceptItem = require './templates/item'
ConceptListTemplate = require './templates/list'
ConceptViewMain = require './templates/concepts'

class ConceptView extends Backbone.View

  play: (evt) ->
    @model.playAudio()
    return false

  template: ConceptItem

  render: ->
    translation_language = app.options.getSetting('help_language')

    fallback = false
    translations = @model.getTranslationsToLang translation_language
    txl_string = (a.get('concept_value') for a in translations).join(', ')

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
      userlang: translation_language
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

  calculateContentHeight: ->
    header_height = $('.aajege-header').height()
    window_height = $(window).height()

    @$el.find('#concepts_content').css('height',
      "#{window_height - header_height - 50}px"
    )

    return false

  render: ->

    translation_language = app.options.getSetting('help_language')

    category = _.first app.categories.where
      category: @for_category

    category_concepts = category.getConcepts
      language: 'sma'

    category_concepts = _.sortBy category_concepts,
      (c) -> c.get('concept_value')

    @next = 1
    @prev = null

    getTxl = (m) =>
      translations = m.getTranslationsToLang translation_language
      txl_string = (a.get('concept_value') for a in translations).join(', ')
      m.set('txl_string', txl_string)

    sortTxl = (m) -> return m.get('txl_string')

    category_concepts = _.sortBy category_concepts.map(getTxl), sortTxl

    @concepts_in_order = category_concepts

    initial = new ConceptView {
      model: category_concepts[0]
    }

    @current_concept_view = initial

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

    @$el.html @template {
      category: category
      models: @concepts_in_order
      initial_model: initial.render().$el.html()
      get_success_color: get_success_color
      getTxl: getTxl
    }

    @$el.find('ul#concept-list li:first').addClass('ui-btn-active-d')
    @calculateContentHeight()

    this
