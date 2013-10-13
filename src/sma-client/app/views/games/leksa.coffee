UserLog = require 'models/user_log_entry'

LeksaTemplate = require './templates/leksa'
LeksaErrorTemplate = require './templates/leksa_error_template'

LeksaQuestionImageToWord = require './templates/leksa_question_image_to_word'
LeksaQuestionWordToWord = require './templates/leksa_question_image_to_word'
LeksaQuestionWordToImage = require './templates/leksa_question_word_to_image'
StatTemplate = require './templates/stat_block'
LevelCompleted = require './templates/leksa_level_completed'


#
##
## ##

fadeUp = (elem) ->
  elem.fadeOut(1500)
    .queue (nxt) ->
      $(this).remove()
      nxt()
  return false

module.exports = class LeksaView extends Backbone.View

  id: "leksa"

  template: LeksaTemplate

  question_template: (context) ->
    console.log context.q_type
    tpl = switch context.q_type
      when "image_to_word" then LeksaQuestionImageToWord
      when "word_to_word" then LeksaQuestionWordToWord
      when "word_to_image" then LeksaQuestionWordToImage
    return tpl context

  leksa_error_template: LeksaErrorTemplate

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

  correctAnswer: (q, user_input) ->
    # Give user feedback that they were correct, and show the set done options.

    user_answer_concept = q.answer
    correct_answer_concept = q.question

    $(user_input).addClass('correct')
    usr_msg = $("<a href='#' class='correct usr_msg'>Correct</a>")
    $(user_input).parent().append usr_msg
    @logConcept(q.generator, correct_answer_concept, true)
    $('.set_done_options').show()
    fadeUp usr_msg
    setTimeout((() => @$el.find('#menu_next').click()), 1200)
    clearInterval(@countdown_handle)
    @$el.find('#points_for_question').fadeIn(100)
    return false

  logConcept: (question_generator, concept, correct) ->
    # Log the concept that the user was prompted with, with a correct/incorrect
    # value

    #
    # Use the concept_value, but if it's an image, then we want to find
    # translations that are words corresponding to the language of the question
    concept_name = concept.get('concept_value')
    if concept.get('concept_type') == 'img'
      _to = question_generator.get('filters').to_language
      _lang_to_filt = (c) => c.get('language') == _to
      _transl = app.conceptdb.getTranslationsOf(concept).filter _lang_to_filt
      if _transl.length > 0
        concept_name = _transl[0].get('concept_value')

    if correct
      points_given = @cur_points
    else
      points_given = 0
    #
    # Create the log entry in the user progression
    log = app.leksaUserProgression.logActivity
      game_name: "leksa"
      question_concept: concept.get('id')
      question_concept_value: concept_name
      question_correct: correct
      question: question_generator
      points: points_given
      cycle: question_generator.get('cycle')

    return true

  incorrectAnswer: (q, user_input) ->

    user_answer_concept = q.answer
    correct_answer_concept = q.question
    # Give user visual feedback on incorrect, add user log.

    # TODO: generate incorrect log entry only on first incorrect attempt, not
    # on each incorrect attempt, but log instance of user progression for word?

    $(user_input).addClass('incorrect')
    usr_msg = $('<a href="#" class="incorrect usr_msg">Try again!</a>')
    $(user_input).parent().append usr_msg
    @logConcept(q.generator, correct_answer_concept, false)
    fadeUp usr_msg
    false

  updateLogPanel: (entry) ->
    # Collate results from app.leksaUserProgression collection, display
    # them.
    concept_prog = app.leksaUserProgression.collateConcepts app.conceptdb
    $('#stat_block').html StatTemplate
      total: app.leksaUserProgression.models.length
      correct: app.leksaUserProgression.totalCorrect()
      concept_progress: concept_prog
      total_points: app.leksaUserProgression.countPoints()

  # # #
  # # #  Progress bar
  # # #

  setIndividualAnswerProgress: (count, total, note) ->
    prog = @$el.find "#leksa_progress_indiv"
    prog.progressbar({value: (count/total)*100})
    prog.find('.progress_label').text(note)
    return false

  setProgress: (count, total) ->
    prog = @$el.find "#leksa_progress"
    prog.progressbar({value: (count/total)*100})
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
    @q = app.questiondb.selectQuestionByProg(
      @leksa_category,
      level_constraint
    )

    # TODO: feedback to user that they haven't completed this yet or have
    # already-- if already, repeat
    if @q == false
      console.log "Complete!"
      finished_level = LevelCompleted()
      @$el.find('#leksa_question').html(finished_level)
      return false

    level_note = "Level #{@q.generator.get('level')}"
    @setProgress(@q.current_count, @q.question_total)
    @setIndividualAnswerProgress(
      @q.total_correct,
      @q.question_total*3,
      level_note
    )

    if not @q.question
      @$el.find('#leksa_question').html @leksa_error_template
        error_msg: "A question could not be generated from these parameters"
      return false

    #
    # Render the template for the question

    @$el.find('#leksa_question').html @question_template
      instance: @q
      chunker: arrayChunk
      audio: @q.question.hasAudio()
      q_type: @q.generator.get('type')

    @$el.find('#leksa_question a.answerlink.text').textfill
      minFontPixels: 18
      maxFontPixels: 36

    @cur_points = @q.generator.get('points')
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
      answer_value = @q.answer.get('concept_value')
      window.last_user_input = answerlink
      if user_input == answer_value
        # If user is correct, stop watching for additional clicks
        @$el.find('#leksa_question a.answerlink').unbind('click').click (evt) ->
          return false
        @correctAnswer(@q, answerlink)
      else
        @incorrectAnswer(@q, answerlink)
      #
      # rebind event to null result incase user clicks multiple times
      answerlink.unbind('click').click (evt) -> return false
      return false

    app.router.refreshCurrentPage()

    playFirst = =>
      if app.options.getSetting('enable_audio') and @q.generator.get('sound')
        @q.question.playAudio()

    # Delay first sound playing as leksa page renders
    if not @first
      setTimeout(playFirst, 1500)
      @first = false
    else
      playFirst()

    @$el.find('#question_play').click () =>
      @q.question.playAudio('questionSound')
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
    app.leksaUserProgression.on('add', @updateLogPanel)

    return this