Question = require 'models/question'
LevelComplete = require '/models/exceptions/level_complete'

module.exports = class QuestionDB extends Backbone.Collection
  model: Question

  url: () ->
    if app.server.offline_media
      return "data/leksa_questions.json"
    return app.server.path + "/data/leksa_questions.json"

  initialize: () ->
    @fetch_tries = 0

    @fetch
      success: () =>
        app.loadingTracker.markReady('leksa_questions.json')
        mod_count = app.questiondb.models.length
        console.log "fetched leksa_questions.json (#{mod_count})"
        @offline = true
      error: () ->
        if app.debug
          console.log "Error fetching leksa_questions.json."
        @fetch_tries += 1
        if @fetch_tries < 3
          @fetch(offline=true)
        else
          console.log "Tried fetching leksa_questions.json too many times"

  removeNonFunctioning: (qs) ->
    return qs.filter (c) ->
      _fails = c.get('fails')
      if not _fails
        return true
      if _fails and _fails == false
        return false
    
  filterQuestionsByCategory: (category) ->
    # If a category does not have any questions, create the questions from the
    # default templates.
    #

    qs = @removeNonFunctioning @where({'category': category})
    if qs.length == 0
      # TODO: need to replace filter semantics-- store in local db for user?
      qs = @removeNonFunctioning @where({'category': 'DEFAULT_GROUP'})
      cat = _.first app.categories.where({category: category})
      cat_semantics = cat.get('semantics')
      adjusted_qs = []
      for q in qs
        new_q = q.clone()
        new_q.set('category', category)
        _filters = new_q.get('filters')
        _sims = new_q.get('answer_similarity')
        # copy, so this saves to obj
        _filters.semantics = cat_semantics
        _sims.semantics = cat_semantics

        adjusted_qs.push new_q
      qs = adjusted_qs
    return qs

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

    question_instance = false
    while not question_instance and tries <= max_tries
      category_qs = @filterQuestionsByCategory(category)
      level_constraint_qs = category_qs.filter(level_constraint)

      if app.debug
        console.log "Level constraint questions: "
        console.log ("#{q.get('category')}/#{q.get('level')}" for q in level_constraint_qs)

      if level_constraint_qs.length > 0
        qs = level_constraint_qs
      else
        qs = category_qs

      completed = false
      user_cycle = app.userprogression.cycle_for_category(category)

      if @needs_next
        user_cycle += 1
      progression_qs = @orderQuestionsByProgression(qs, user_cycle)
      if app.debug
        console.log "Ordered by progression: "
        console.log ("#{q.get('category')}/#{q.get('level')}" for q in progression_qs)
      
      # for testing only, so far.. 
      if progression_qs.length == 0
        progression_qs_next = @orderQuestionsByProgression(qs, user_cycle+1)
        if app.debug
          console.log "Ordered by progression plus one: "
          console.log ("#{q.get('category')}/#{q.get('level')}" for q in progression_qs_next)
      else
        progression_qs_next = []

      if progression_qs_next.length > 0 and progression_qs.length == 0 and not @needs_next
        if app.debug
          console.log "Uh oh, this."
        user_cycle += 1
        progression_qs = @orderQuestionsByProgression(qs, user_cycle)
        completed = true

      @needs_next = false

      if progression_qs
        qs = progression_qs
      else
        qs = qs

      if qs.length == 0
        return false

      q = _.first qs
      q.set('cycle', user_cycle)

      # TODO: this gets the cycle, but nothing is incrementing when the level
      # is completed
      current_question_cycle = q.cycle_for_progression()

      if app.debug
        console.log "current cycle: #{current_question_cycle}"
        console.log "question level: #{q.get('level')}"
        console.log "user's cycle for category: #{current_question_cycle}"

      try
        question_instance = q.find_concepts(app.conceptdb, {ordering: ordering})
        if app.debug
          _msg_q_cycle = question_instance.generator.get('cycle')
          console.log "question cycle: #{_msg_q_cycle}"
        if completed
          if app.debug
            console.log "question cycle complete for: #{q}"
          question_instance = false
          @needs_next = true
          return question_instance
      catch e
        console.log "TODO: caught LevelComplete"
        if e instanceof LevelComplete
          question_instance = false
          if app.debug
            console.log "question cycle complete for: #{q}"

      tries += 1

    return question_instance
