module.exports = class HelloView extends Backbone.View

  className: 'hello'
  id: "hello"

  template: require './templates/hello'

  render: ->
    @$el.html @template
    this
