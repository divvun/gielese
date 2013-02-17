
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

  className: 'conceptlist'

  template: require './templates/concept_list'

  initialize: () ->
    super
    @_conceptViews = []
    #
    # Filter out images, will display these via translations
    filtered_collection = @collection.filter (c) ->
      (c.get('concept_type') != 'img') and (c.get('concept_type') != 'lyd')
    _(filtered_collection).each (concept) =>
      @_conceptViews.push new UpdatingConceptView({
        model: concept
      })
      
  render: ->
    @$el.html @template

    _(@_conceptViews).each (cv) =>
      _el = cv.render().$el.html()
      @$el.find('ul.concepts').append(_el)

    this
