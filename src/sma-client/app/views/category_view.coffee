module.exports = class CategoryMenu extends Backbone.View

  className: 'hello'
  id: "hello"

  template: require './templates/category_menu'

  render: ->
    @$el.html @template
    this
