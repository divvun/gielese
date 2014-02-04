LevelCompleteTemplate = require '/views/games/templates/leksa_level_completed'

module.exports = class LevelComplete extends Backbone.View

  id: "level_complete"

  template: LevelCompleteTemplate

  render: ->
    @$el.html @template

    this

