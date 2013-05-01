
class UpdatingConceptView extends Backbone.View
  template: require './templates/concept_item'

  render: ->
    @$el.html @template({
      model: @model
      concept_value: @model.get('concept_value')
      concept_type: @model.get('concept_type')
      translations: app.conceptdb.getTranslationsOf @model
    })

    this

module.exports = class ConceptList extends Backbone.View

  events:
    'click .audio_link': 'findAudio'

  findAudio: (event) ->
    concept_id = $(event.target).parent('a.audio_link').attr('data-concept')
    concept = app.conceptdb.getByCid concept_id

    has_media = concept.get('media')
    sound_id = "wordListSound"
    if app.options.enable_audio and ('audio' of has_media)
      if has_media.audio.length > 0
        has_audio_file = has_media.audio[0].path
        if has_audio_file and soundManager.enabled
          soundManager.destroySound(sound_id)
          soundManager.createSound({
             id: sound_id
             url: "/static#{has_audio_file}"
          })
          soundManager.play(sound_id)

    return false

  className: 'conceptlist'

  template: require './templates/concept_list'

  initialize: () ->
    super
    @_conceptViews = []
    #
    # Filter out images, will display these via translations
      
  render: ->
    @$el.html @template

    filtered_collection = @collection.where({
      'concept_type': 'img'
    }).filter (o) ->
      "BODYPART" in o.get('semantics')

    _(filtered_collection).each (concept) =>
      @_conceptViews.push new UpdatingConceptView({
        model: concept
      })

    _(@_conceptViews).each (cv) =>
      _el = cv.render().$el.html()
      @$el.find('ul[data-role="listview"]').append(_el)

    this
