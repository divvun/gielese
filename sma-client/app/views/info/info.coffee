InfoTemplate = require './templates/info'

module.exports = class InfoPage extends Backbone.View

  id: "infoPage"

  template: InfoTemplate

  render: ->
    @$el.html @template

    this
