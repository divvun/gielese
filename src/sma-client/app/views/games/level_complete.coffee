LevelCompleteTemplate = require './templates/leksa_level_completed'

module.exports = class LevelComplete extends Backbone.View

  id: "level_complete"

  events:
    'click a#repeat': 'navigateBack'

  template: LevelCompleteTemplate

  navigateBack: (e) ->
    e.preventDefault()
    window.history.back()

  render: ->
    @$el.html @template

    this

