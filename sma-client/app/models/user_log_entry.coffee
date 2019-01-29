module.exports = class UserLogEntry extends Backbone.Model

  url: () ->
    return app.server.path + "/user/data/log/"

  attributes:
    game_name: false        # string
    question_concept: false # related?
    question_correct: false # boolean
    cycle: false

  do_not_push: [
    "sid"
    "dirty"
  ]

  toJSON: (options) ->
    # TODO: setting to keep everything?
    attrs = @attributes
    for i in @do_not_push
      delete attrs[i]
    return _.clone(attrs)

  initialize: () ->
    @set('sid', 'new')
    @set('dirty', true)
    @set('_id', @cid)

