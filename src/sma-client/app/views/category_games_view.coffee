module.exports = class CategoryGames extends Backbone.View

  className: 'hello'
  id: "hello"

  template: require './templates/category_games_menu'

  render: ->
    @$el.html @template {
      category: @category
    }
    this

