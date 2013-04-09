module.exports = class ErrorView extends Backbone.View

  className: 'error'
  id: "error"

  template: require './templates/error'

  render: ->
    @$el.html @template
    this

