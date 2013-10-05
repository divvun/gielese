ErrorTemplate = require './templates/error'

module.exports = class ErrorView extends Backbone.View

  className: 'error'
  id: "error"

  template: ErrorTemplate

  render: ->
    @$el.html @template
    this

