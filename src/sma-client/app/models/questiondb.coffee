
Question = require 'models/question'

chooseQuestionbyProgression = (questions, userprogression) ->
  # if userprogression.length == 0
  #   highest_completed_level = 0
  # else
  # 	highest_completed_level = questions
  #     .filter (q) =>
  #       q.user_completed_question(userprogression)
  #     .map (q) =>
  #       {'question': q, 'level': q.get('level')}

  #   highest_completed_level = _.max(
  #       _.sortBy(highest_completed_level, 'level').map (q) -> q.level
  #   )
      
  if window.app.debug
    console.log "choosing question by progression"
  filtered_questions = questions.filter (q) =>
      return not q.user_completed_question(userprogression)
    .map (q) ->
      {'question': q, 'level': q.get('level')}

  filtered_questions = _.sortBy(filtered_questions, 'level')
  return [filtered_questions[0].question]

module.exports = class QuestionDB extends Backbone.Collection
  model: Question

  selectLeksaConcepts: (userprogression) ->
    #
    # Select a question
    #
    # Max attempts 5, if cannot generate a question from the template,
    # then skip. The question will be marked as failing, and filtered
    # out of the cycle

    [tries, max_tries] = [0, 5]

    question_instance = false
    while not question_instance and tries <= max_tries
      functioning_questions = app.questiondb.models.filter (c) ->
        _fails = c.get('fails')
        if not _fails
          return true
        if _fails and _fails == false
          return false

      user_progression_concepts = chooseQuestionbyProgression(
        functioning_questions,
        userprogression
      )
      q = _.shuffle(user_progression_concepts)[0]

      question_instance = q.find_concepts( app.conceptdb
                                         , window.app.leksaUserProgression
                                         )
      tries += 1

    return question_instance

