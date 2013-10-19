Question = require 'models/question'

chooseQuestionbyProgression = (questions, userprogression) ->

  if app.debug
    console.log "choosing question by progression"
  _filtered_questions = questions.filter (q) =>
    # TODO: for highest cycle available
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
        mod_count = app.questiondb.models.length
        console.log "fetched leksa_questions.json (#{mod_count})"

  removeNonFunctioning: (qs) ->
    return qs.filter (c) ->
      _fails = c.get('fails')
      if not _fails
        return true
      if _fails and _fails == false
        return false
    
  filterQuestionsByCategory: (category) ->
    @removeNonFunctioning @where({'category': category})

  orderQuestionsByProgression: (progression, qs) ->
    _.shuffle chooseQuestionbyProgression(
      @removeNonFunctioning(qs),
      progression
    )

  selectQuestionByProg: (category, level_constraint=false) ->
    @selectQuestion(app.leksaUserProgression, category, level_constraint)

  selectQuestion: (userprogression, category, level_constraint=false) ->
    #
    # Select a question
    #
    # Max attempts 5, if cannot generate a question from the definition,
    # then skip. The question will be marked as failing, and filtered
    # out of the cycle.
    #
    # TODO: log a server error.

    [tries, max_tries] = [0, 5]

    if level_constraint == false
      level_constraint = (level) -> true

    # TODO: for now just ordering by progression and dispalying everything
    # anyway

    question_instance = false
    while not question_instance and tries <= max_tries
      category_qs = @filterQuestionsByCategory(category)
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

      current_cycle = q.find_cycle_for_progression(
        app.leksaUserProgression
      )
      if not isFinite(current_cycle)
        console.log "wasnt finite"
        current_cycle = 1
      console.log "initial progression cycle: #{current_cycle}"
      # q.set('cycle', current_cycle)

      question_instance = q.find_concepts( app.conceptdb
                                         , app.leksaUserProgression
                                         )
      console.log "instance cycle: #{question_instance.generator.get('cycle')}"
      tries += 1

    return question_instance
