module.exports = class CategoryGames extends Backbone.View

  id: "category_games"

  template: require './templates/category_games_menu'

  render: ->
    @$el.html @template {
      category: @category
    }

    # TODO: Grab from XML db somehow
    category_images =
      "GREETINGS": "http://placekitten.com/g/300/500"
      "BODYPART": "http://placekitten.com/g/500/600"
      "FOOD": "http://placekitten.com/g/400/600"

    category_image = category_images[@category]

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

