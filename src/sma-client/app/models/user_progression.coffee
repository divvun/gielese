module.exports = class UserProgression extends Backbone.Collection

  collateConcepts: (conceptdb) ->
    # for each log entry, collect concept and correct 1/0, sum correct / length for each concept
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

  # NOTES on things to track: 
  # external_uid: 324233
  # last_question: ["leksa", 24]
  # question_types: [
  #     { type: "image_to_word"
  #     , game_play_count: 32
  #     , game_correct_count: 10
  #     }
  #   , { type: "word_to_image"
  #     , game_play_count: 18
  #     , game_correct_count: 18
  #     }
  # ]
  # concepts: [
  #     { concept_id: 3
  #     , presented_as_correct_answer_count: 0
  #     , presented_as_question_count: 0
  #     , answer_correct: 0
  #     , question_correct: 0
  #     }
  #   , { concept_id: 2
  #     , presented_as_correct_answer_count: 0
  #     , presented_as_question_count: 0
  #     , answer_correct: 0
  #     , question_correct: 0
  #     }
  # ]
  # games: [
  #     { game_name: "leksa"
  #     , game_play_count: 24
  #     , game_correct_count: 18
  #     }
  #   , { game_name: "morfa"
  #     , game_play_count: 24
  #     , game_correct_count: 18
  #     }
  # ]


