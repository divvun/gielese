Question = require 'models/question'
LevelComplete = require '/models/exceptions/level_complete'

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

  orderQuestionsByProgression: (qs, user_cycle) ->
    userprogression = app.userprogression

    questionByProg = (questions, user_cycle) =>
    
      if app.debug
        console.log "choosing question by progression"
    
      _filtered_questions = questions.filter (q) =>
        # TODO: for highest cycle available
        return not q.user_completed_question({cycle: user_cycle})
    
      filtered_questions = _filtered_questions.map (q) ->
        {'question': q, 'level': q.get('level')}
    
      filtered_questions = _.sortBy(filtered_questions, 'level')
    
      if filtered_questions.length > 0
        return [_.first(filtered_questions).question]
      else
        return false

    _.shuffle questionByProg(
      @removeNonFunctioning(qs),
      user_cycle
    )

  selectQuestionByProg: (category, level_constraint=false) ->
    @selectQuestion(category, level_constraint)

  selectQuestion: (category, level_constraint=false, ordering=false) ->
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

      # TODO: find user's current cycle on category from progression
      # ... by looking at max cycle for each question, +1 of which shouldn't be
      # available unless the cycle has been completed
      user_cycle = 1
      progression_qs = @orderQuestionsByProgression(qs, user_cycle)

      if progression_qs
        qs = progression_qs
      else
        qs = qs

      if qs.length == 0
        return false

      q = _.first qs

      current_question_cycle = q.cycle_for_progression()

      if not isFinite(current_cycle)
        if app.debug
          console.log "wasnt finite"
        current_cycle = 1

      if app.debug
        console.log "question level: #{q.get('level')}"
        console.log "user's cycle for category: #{current_cycle}"

      try
        question_instance = q.find_concepts(app.conceptdb, {ordering: ordering})
        if app.debug
          _msg_q_cycle = question_instance.generator.get('cycle')
          console.log "question cycle: #{_msg_q_cycle}"
      catch e
        if e instanceof LevelComplete
          question_instance = false
          if app.debug
            console.log "question cycle complete for: #{q}"

      tries += 1

    return question_instance
