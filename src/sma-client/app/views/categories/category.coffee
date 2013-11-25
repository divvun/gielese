Category = require 'models/category'
CategoryTemplate = require './templates/category'
SubcategoryTemplate = require './templates/subcategory'

module.exports = class CategoryGames extends Backbone.View

  id: "category_view"

  events:
    "click a": "clickSound"

  clickSound: (evt) ->
    app.soundEffects.click()
    return true

  template: (params) ->
    if params.subcategory
      return SubcategoryTemplate params
    else
      return CategoryTemplate params

  render: ->
    cats = app.categories.where({category: @category})
    if cats.length > 0
      cat = cats[0]

    subcategory = cat.children()

    if subcategory
      labels = 'cba'
      _labels = labels.split('')

      withLabel = (c) =>
        if _labels.length == 0
          _labels = labels.split('')
        lab = _labels.pop(0)
        return [c, lab]

      chunks = window.arrayChunk(
        withLabel c for c in subcategory,
        3
      )
      subcategory = chunks
      console.log "omgchildren"
    else
      children = false

    window.cat = cat
    if cat.hasImage()
      category_image = cat.hasImage()
    else
      category_image = ''

    @$el.html @template {
      category: cat
      subcategory: subcategory
      background_image: "url('#{category_image}')"
      background_size:  "#{app.screen_width-2}px #{app.screen_height-2}px"
    }

    @$el.css
      "background-size":  "#{app.screen_width-2}px #{app.screen_height-2}px"
      "background-image": "url('#{category_image}')"

    this

