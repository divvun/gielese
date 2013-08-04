﻿UserLogEntry = require 'models/user_log_entry'

module.exports = class UserProgression extends Backbone.Collection

  url: "/user/data/log/"

  model: UserLogEntry

  parse: (resp) ->
    return resp.data

  initialize: () ->
    @storage = new Offline.Storage('leksa-user-progression', @)
    # set after the user successfully authenticates
    if app.has_user
      if navigator.onLine
      	@fetch()

  countPoints: () ->
    points = (m.get('points') for m in @models)
    sum = (memo, num) -> memo + num
    return _.reduce(points, sum, 0)

  logActivity: (opts) ->
    log = @create(opts)
    log.set('dirty', true)
    return log


  collateConcepts: (conceptdb) ->
    # for each log entry, collect concept and correct 1/0, sum correct / length
    # for each concept
    boolToInt = (b) ->
      switch b
        when true  then 1
        when false then 0

    concept_correct = []
    for c in @models
      concept_correct.push [           c.get('question_concept_value')
                           , boolToInt c.get('question_correct')
                           ]

    sorted_values  = _.sortBy(concept_correct, (m) -> m[0])
    grouped_values = _.groupBy(sorted_values, (m) -> m[0])

    totals = {}
    for c_name, c_vals of grouped_values
      _vals = _.flatten [v[1] for v in c_vals]
      _v_correct = _.reduce(_vals, (a,m) -> a + m)
      _v_total   = _vals.length
      totals[c_name] = [_v_correct, _v_total]

    return totals

  totalCorrect: () ->
    models = @models.filter (m) ->
      m.get('question_correct') == true
    models.length

