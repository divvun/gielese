module.exports = class UserLogEntry extends Backbone.Model

  url: "/user/data/log/"

  attributes:
    game_name: false        # string
    question_concept: false # related?
    question_correct: false # boolean

  initialize: (args...) ->
    super args
    @set('dirty', true)

