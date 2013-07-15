module.exports = class UserLogEntry extends Backbone.Model

  url: () ->
    return "/data/concepts/#{@cid}"

  attributes:
    game_name: false        # string
    question_concept: false # related?
    question_correct: false # boolean

