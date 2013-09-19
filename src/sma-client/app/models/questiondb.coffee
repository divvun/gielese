Question = require 'models/question'

chooseQuestionbyProgression = (questions, userprogression) ->

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

  initialize: () ->
    @fetch
      success: () =>
        app.loadingTracker.markReady('leksa_questions.json')
        console.log "fetched leksa_questions.json (#{app.questiondb.models.length})"

  filterQuestionsByCategory: (category, qs) ->

    if category
      category_questions = qs.where({'category': category})
    else
      category_questions = qs

    functioning_questions = category_questions.filter (c) ->
      _fails = c.get('fails')
      if not _fails
        return true
      if _fails and _fails == false
        return false

    _.shuffle(functioning_questions)

  orderQuestionsByProgression: (progression, qs) ->

    category_questions = qs

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

  filterQuestionsByProgression: (progression, category, qs) ->

    if category
      category_questions = qs.where({'category': category})
    else
      category_questions = qs

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

  selectLeksaConcepts: (userprogression, category, level_constraint=false) ->
    #
    # Select a question
    #
    # Max attempts 5, if cannot generate a question from the template,
    # then skip. The question will be marked as failing, and filtered
    # out of the cycle

    [tries, max_tries] = [0, 5]

    # TODO: for now just ordering by progression and dispalying everything
    # anyway

    question_instance = false
    while not question_instance and tries <= max_tries
      category_qs = @filterQuestionsByCategory(category, @)
      level_constraint_qs = category_qs.filter(level_constraint)
      if level_constraint_qs.length > 0
        qs = level_constraint_qs
      else
        qs = category_qs

      progression_qs = @orderQuestionsByProgression(userprogression, qs)

      if progression_qs
        qs = progression_qs
      else
        qs = qs

      if qs.length == 0
        return false

      q = qs[0]

      question_instance = q.find_concepts( app.conceptdb
                                         , app.leksaUserProgression
                                         )
      tries += 1

    return question_instance
