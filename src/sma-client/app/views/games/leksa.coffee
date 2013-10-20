UserLog = require 'models/user_log_entry'

LeksaTemplate = require './templates/leksa'
LeksaErrorTemplate = require './templates/leksa_error_template'

LeksaQuestionImageToWord = require './templates/leksa_question_image_to_word'
LeksaQuestionWordToWord = require './templates/leksa_question_image_to_word'
LeksaQuestionWordToImage = require './templates/leksa_question_word_to_image'
StatTemplate = require './templates/stat_block'
LevelCompleted = require './templates/leksa_level_completed'
LeksaConceptTemplate = require '/views/templates/leksa_concept'

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
    tpl = switch context.q_type
      when "image_to_word" then LeksaQuestionImageToWord
      when "word_to_word" then LeksaQuestionWordToWord
      when "word_to_image" then LeksaQuestionWordToImage
    return tpl context

  leksa_error_template: LeksaErrorTemplate

  events:
    # TODO: test swiping
    'click #menu_next': "newQuestionSameGroup"
    'click .disable_auto_handler': "reset_auto_event"

  reset_auto_event: () ->
    clearInterval @auto_advance_handler
    return true

  newQuestionSameGroup: (evt) ->
    @renderQuestion()
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

  selectQuestionForRendering: ->
    # TODO: wait for ready if not
    if app.questiondb.length == 0 and app.conceptdb.length == 0
      window.last_error = "Question DB and Concept DB not ready."
      app.router.navigate('error')

    if @level_constraint
      level_constraint = @level_constraint
    else
      level_constraint = (level) -> true

    q = app.questiondb.selectQuestionByProg(
      @leksa_category,
      level_constraint
    )

    return q

  renderQuestion: ->
    # Select a question, render it, bind event handlers to each possible
    # answer

    #
    # Hide the question-end options
    $('.set_done_options').hide()

    window.scrollTo(0,0)

    # check if the question has been preselected by the click event in the
    # router
    if @preselected_q?
      if app.debug
        console.log "Pregenerated for click event."
      @q = @preselected_q
      delete @preselected_q
    else
      @q = @selectQuestionForRendering()

    # TODO: feedback to user that they haven't completed this yet or have
    # already-- if already, repeat
    if @q == false
      console.log "Complete!"
      finished_level = LevelCompleted()
      @$el.find('#leksa_question').html(finished_level)
      _log_msg = "LeksaView.render_question: user completed all levels, "
      _log_msg += "unable to recover -"
      _log_msg += "#{q.generator.get('category')}/#{q.generator.get('level')}"
      window.client_log.error(_log_msg)
      return false

    level_note = "Level #{@q.generator.get('level')}"
    @setProgress(@q.current_count, @q.question_total)
    _repeats = @q.generator.get('repetitions')
    if _repeats == 0
      _repeats = 1
    @setIndividualAnswerProgress(
      @q.total_correct,
      @q.question_total*_repeats,
      level_note
    )

    if not @q.question
      _log_msg = "LeksaView.render_question: ungeneratable question - "
      _log_msg += "#{q.generator.get('category')}/#{q.generator.get('level')}"
      window.client_log.error(_log_msg)
      _err_msg = "A question could not be generated from these parameters"
      @$el.find('#leksa_question').html @leksa_error_template
        error_msg: _err_msg
      return false

    #
    # Render the template for the question

    class DummyConcept extends Backbone.Model
      render_concept: () ->
        LeksaConceptTemplate({
          concept: @
          concept_type: @.get('concept_type')
          concept_value: @.get('concept_value')
          additional_class: "no_frame"
        })

    if @q.choices.length == 3 and @q.generator.get('type') == "word_to_image"
      @q.choices.push new DummyConcept
        concept_value: "/static/images/bakgrunn-spill.png"
        concept_type: "img"
      
      @q.choices = _.shuffle @q.choices

    if @q.choices.length == 2 and @q.generator.get('type') == "word_to_image"
      @q.choices.push new DummyConcept
        concept_value: "/static/images/bakgrunn-spill.png"
        concept_type: "img"

      @q.choices.push new DummyConcept
        concept_value: "/static/images/bakgrunn-spill.png"
        concept_type: "img"
      
      @q.choices = _.shuffle @q.choices

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
    if @pregenerated?
      delete @pregenerated
    else
      if not @first
        setTimeout(playFirst, 1500)
        @first = false
      else
        playFirst()

    @$el.find('#question_play').click () =>
      if app.debug?
        console.log "Play:"
        console.log @q.question
      @current_audio = @q.question.playAudio()
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

    autoAdvance = () =>
      # TODO: check if audio has played first
      @renderQuestion()
      console.log @current_audio

    if @auto_advance
      # TODO: delete this when user navigates away
      @auto_advance_handler = setInterval( autoAdvance, 7000)

    @first = true

    # Bind an event to user progression-- TODO: move elsewhere
    app.leksaUserProgression.on('add', @updateLogPanel)

    return this
