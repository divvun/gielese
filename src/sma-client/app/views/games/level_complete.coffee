LevelCompleteTemplate = require './templates/leksa_level_completed'

module.exports = class LevelComplete extends Backbone.View

  id: "level_complete"

  events:
    'click a#repeat': 'navigateBack'

  template: LevelCompleteTemplate

  navigateBack: (e) ->
    e.preventDefault()
    window.location.hash = window.last_category
    delete window.last_category

  render: () ->
    @$el.html @template {category: @category}
    setTimeout( app.soundEffects.correct, 500 )
    this

