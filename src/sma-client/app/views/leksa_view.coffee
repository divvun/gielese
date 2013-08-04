
StatTemplate = require 'views/templates/stat_block'
LevelCompleted = require 'views/templates/leksa_level_completed'

UserLog = require 'models/user_log_entry'


#
##
## ##

fadeUp = (elem) ->
    elem.fadeOut(1500)
        .queue (nxt) ->
            $(this).remove()
            nxt()

    # .remove()
    # elem.remove()
    return false

module.exports = class LeksaView extends Backbone.View

  id: "leksa"

  question_template: require './templates/leksa_question'
  template: require './templates/leksa'
  leksa_error_template: require './templates/leksa_error_template'

  events:
    'click #show-panel': "revealOptionsPanel"
    'click #show-user-panel': "revealUserPanel"
    # TODO: test swiping
    'swiperight body': "revealOptionsPanel"
    'swipeleft body': "revealUserPanel"
    'click #menu_next': "newQuestionSameGroup"

  newQuestionSameGroup: (evt) ->
    @renderQuestion()
    return false
    
  # # #
  # # #  Panels
  # # #
  
  # Left panel
  revealOptionsPanel: (evt) ->
    panel_options =
      position: "left"
    $('#leksa-options').panel('open', panel_options)
    return false

  # Right panel
  revealUserPanel: (evt) ->
    panel_options =
      position: "right"
    $('#user-options').panel('open', panel_options)
    return false

  # # #
  # # #  Answer logging
  # # #

  correctAnswer: (question, user_input, user_answer_concept, correct_answer_concept) ->
    # Give user feedback that they were correct, and show the set done options.

    $(user_input).addClass('correct')
    usr_msg = $("<a href='#' class='correct usr_msg'>Correct</a>")
    $(user_input).parent().append usr_msg
    @logConcept(question, correct_answer_concept, true)
    $('.set_done_options').show()
    fadeUp usr_msg
    setTimeout((() => @$el.find('#menu_next').click()), 1200)
    clearInterval(@countdown_handle)
    @$el.find('#points_for_question').fadeIn(100)
    return false

  logConcept: (question, concept, correct) ->
    # Log the concept that the user was prompted with, with a correct/incorrect value

    #
    # Use the concept_value, but if it's an image, then we want to find
    # translations that are words corresponding to the language of the question
    concept_name = concept.get('concept_value')
    if concept.get('concept_type') == 'img'
      _to = question.get('filters').to_language
      _transl = app.conceptdb.getTranslationsOf(concept).filter (c) -> c.get('language') == _to
      if _transl.length > 0
        concept_name = _transl[0].get('concept_value')

    if correct
      points_given = @cur_points
    else
      points_given = 0
    #
    # Create the log entry in the user progression
    log = window.app.leksaUserProgression.logActivity({
      game_name: "leksa"
      question_concept: concept.get('id')
      question_concept_value: concept_name
      question_correct: correct
      question: question
      points: points_given
    })

    return true
    
  incorrectAnswer: (question, user_input, user_answer_concept, correct_answer_concept) ->
    # Give user visual feedback on incorrect, add user log.

    # TODO: generate incorrect log entry only on first incorrect attempt, not
    # on each incorrect attempt, but log instance of user progression for word?

    $(user_input).addClass('incorrect')
    usr_msg = $('<a href="#" class="incorrect usr_msg">Try again!</a>')
    $(user_input).parent().append usr_msg
    @logConcept(question, correct_answer_concept, false)

    fadeUp usr_msg

    return false

  updateLogPanel: (entry) ->
    # Collate results from window.app.leksaUserProgression collection, display them.
    $('#stat_block').html StatTemplate {
        total: window.app.leksaUserProgression.models.length
        correct: window.app.leksaUserProgression.totalCorrect()
        concept_progress: window.app.leksaUserProgression.collateConcepts(app.conceptdb)
        total_points: window.app.leksaUserProgression.countPoints()
    }

  # # #
  # # #  Progress bar
  # # #
  
  setIndividualAnswerProgress: (count, total) ->
    prog = @$el.find "#leksa_progress_indiv"
    prog.progressbar({value: (count/total)*100})
    return false

  setProgress: (count, total, note) ->
    prog = @$el.find "#leksa_progress"
    prog.progressbar({value: (count/total)*100})
    prog.find('.progress_label').text(note)
    return false


  # # #
  # # #  Question rendering
  # # #
    
  renderQuestion: ->
    # Select a question, render it, bind event handlers to each possible
    # answer

    # 
    # Hide the question-end options
    $('.set_done_options').hide()

    # TODO: smooth scroll
    window.scrollTo(0,0)

    # TODO: wait for ready if not 
    if app.questiondb.length == 0 and app.conceptdb.length == 0
      window.last_error = "Question DB and Concept DB not ready."
      app.router.navigate('error')

    if @level_constraint
      level_constraint = @level_constraint
    else
      level_constraint = (level) -> true

    # TODO: category from user
    q_instance = app.questiondb.selectLeksaConcepts( window.app.leksaUserProgression
                                                   , @leksa_category
                                                   , level_constraint
                                                   )

    # TODO: feedback to user that they haven't completed this yet or have already-- if already, repeat
    if q_instance == false
      console.log "Complete!"
      finished_level = LevelCompleted()
      @$el.find('#leksa_question').html(finished_level)
      return false

    level_note = "Level #{q_instance.generator.get('level')}"
    @setProgress(q_instance.current_count, q_instance.question_total, level_note)
    @setIndividualAnswerProgress(q_instance.total_correct, q_instance.question_total*3)

    if not q_instance.question
      question_block = @leksa_error_template({
        error_msg: "A question could not be generated from these parameters"
      })
      @$el.find('#leksa_question').html(question_block)
      return false

    #
    # Render the template for the question
    console.log q_instance.generator.get('type')
    question_block = @question_template {
      instance: q_instance
      chunker: arrayChunk
      audio: q_instance.question.hasAudio()
      q_type: q_instance.generator.get('type')
    }

    @$el.find('#leksa_question').html(question_block)
    @$el.find('#leksa_question a.answerlink.text').textfill({
        minFontPixels: 18
        maxFontPixels: 36
    })

    @cur_points = q_instance.generator.get('points')
    @$el.find('#points_for_question .points').html("+#{@cur_points}")
    @$el.find('#points_for_question').hide()

    countdownPoints = (evt) =>
        if @cur_points > 5
          @cur_points -= 1
          @$el.find('#points_for_question .points').html("+#{@cur_points}")

    @countdown_handle = setInterval(countdownPoints, 1000)

    #
    # Register answer click handlers
    @$el.find('#leksa_question a.answerlink').click (evt) =>
      answerlink = $(evt.target).parents('.answerlink')
      user_input = answerlink.attr('data-word')
      answer_value = q_instance.answer.get('concept_value')
      window.last_user_input = answerlink
      if user_input == answer_value
        # If user is correct, stop watching for additional clicks
        @$el.find('#leksa_question a.answerlink').unbind('click').click (evt) ->
          return false
        @correctAnswer(q_instance.generator, answerlink,
                        q_instance.answer, q_instance.question)
      else
        @incorrectAnswer(q_instance.generator, answerlink,
                           q_instance.answer, q_instance.question)
      #
      # rebind event to null result incase user clicks multiple times
      answerlink.unbind('click').click (evt) -> return false
      return false

    app.router.refreshCurrentPage()

    playFirst = () ->
      if q_instance.question.get('sound')
        q_instance.question.playAudio('questionSound')

    # Delay first sound playing as leksa page renders
    if not @first
      setTimeout(playFirst, 1500)
      @first = false
    else
      playFirst()

    @$el.find('#question_play').click () =>
      q_instance.question.playAudio('questionSound')
      return false
      
    return true

  render: ->
    # if user ends up on front page due to error and comes back here, events
    # are not registered
    # Render template and insert a question

    @$el.html @template {
      leksa_category: @leksa_category
    }

    @$el.find('#points_for_question').hide()

    @renderQuestion()
    @first = true
    # Bind an event to user progression-- TODO: move elsewhere
    window.app.leksaUserProgression.on('add', @updateLogPanel)

    return this

