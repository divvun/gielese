LevelComplete = require '/models/exceptions/level_complete'

module.exports = class LevelComplete extends Backbone.View

  id: "levelComplete"

  template: LevelComplete

  render: ->
    @$el.html @template

    this

