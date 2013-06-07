
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
      
  if app.debug
    console.log "choosing question by progression"
  _filtered_questions = questions.filter (q) =>
      return not q.user_completed_question(userprogression)

  filtered_questions = _filtered_questions.map (q) ->
      {'question': q, 'level': q.get('level')}

  filtered_questions = _.sortBy(filtered_questions, 'level')

  if filtered_questions.length > 0
    return [filtered_questions[0].question]
  else
  	return false

module.exports = class QuestionDB extends Backbone.Collection
  model: Question

  url: "/data/leksa_questions.json"

  filterQuestionsByProgression: (progression, category) ->

    if category
      category_questions = @where({'category': category})
    else
      category_questions = @

    functioning_questions = category_questions.filter (c) ->
      _fails = c.get('fails')
      if not _fails
        return true
      if _fails and _fails == false
        return false

    user_progression_questions = chooseQuestionbyProgression(
      functioning_questions,
      progression
    )

    qs = _.shuffle(user_progression_questions)
    return qs

  selectLeksaConcepts: (userprogression, category) ->
    #
    # Select a question
    #
    # Max attempts 5, if cannot generate a question from the template,
    # then skip. The question will be marked as failing, and filtered
    # out of the cycle

    [tries, max_tries] = [0, 5]

    question_instance = false
    while not question_instance and tries <= max_tries
      qs = @filterQuestionsByProgression(userprogression, category)

      if qs.length == 0
      	return false

      q = qs[0]
      
      question_instance = q.find_concepts( app.conceptdb
                                         , app.leksaUserProgression
                                         )
      tries += 1

    return question_instance

