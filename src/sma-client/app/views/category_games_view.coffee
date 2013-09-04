Category = require 'models/category'

module.exports = class CategoryGames extends Backbone.View

  id: "category_games"

  template: require './templates/category_games_menu'

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

    @$el.html @template {
      category: @category
      subcategory: subcategory
    }

    window.cat = cat
    if cat.hasImage()
      category_image = cat.hasImage()
    else
      category_image = ''

    # category_image = false
    # count = 5
    # concepts = app.conceptdb.where({language: "sma", semantics: [@category]})
    # while count > 0 and category_image == false
    #   c = concepts.pop(0)
    #   if c.hasImage()
    #   	category_image = c.hasImage()

    @$el.css( "background-image"
            , "url('#{category_image}')"
            )

    this

