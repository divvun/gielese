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

  auto_advance: false

  level_constraint: (question) =>
    question.get('level') >= @attributes.level_constraint

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
    clearInterval @countdown_handle
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

    answer_offset = $(user_input).offset()
    width_offset = ($(user_input).width() / 2) - (@pts_bubble.width() / 2)
    height_offset = @pts_bubble.height() / 2

    $(user_input).addClass('correct')
    @logConcept(q.generator, correct_answer_concept, true)
    $('.set_done_options').show()
    setTimeout((() => @$el.find('#menu_next').click()), 1200)
    clearInterval(app.wait_handler)

    @pts_bubble.css('top',  "#{answer_offset.top-height_offset}px")
    @pts_bubble.css('left', "#{answer_offset.left+width_offset}px")

    @pts_bubble.fadeIn(100)
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
      if points_given < 0
        points_given = 0
    else
      points_given = 0
    #
    # Create the log entry in the user progression
    # TODO: remove question, rely only on question_category and ..._level
    log = app.leksaUserProgression.logActivity
      game_name: "leksa"
      question_concept: concept.get('concept_value')
      question_concept_value: concept_name
      question_correct: correct
      question_category: question_generator.get('category')
      question_category_level: question_generator.get('level')
      points: points_given
      cycle: question_generator.get('cycle')

    return true

  incorrectAnswer: (q, user_input) ->
    # NB: do not clear the point countdown handler here

    if @cur_points > 10
      @cur_points -= 10

    user_answer_concept = q.answer
    correct_answer_concept = q.question
    # Give user visual feedback on incorrect, add user log.

    # TODO: generate incorrect log entry only on first incorrect attempt, not
    # on each incorrect attempt, but log instance of user progression for word?

    $(user_input).addClass('incorrect')
    @logConcept(q.generator, correct_answer_concept, false)
    false

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

    if @attributes.level_constraint
      level_constraint = @level_constraint
    else
      level_constraint = (level) -> true

    q = app.questiondb.selectQuestionByProg(
      @attributes.leksa_category,
      level_constraint
    )

    return q

  displayUserPoints: ->
    count = app.leksaUserProgression.countPoints()
    @$el.find('#point_total').html count
    return

  renderQuestion: ->
    # Select a question, render it, bind event handlers to each possible
    # answer

    #
    # Hide the question-end options
    $('.set_done_options').hide()

    if app.wait_handler?
      clearInterval app.wait_handler
    
    window.scrollTo(0,0)

    @displayUserPoints()

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
    else
      _repeats += 1

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

    @$el.find('#leksa_question').html @question_template
      instance: @q
      chunker: arrayChunk
      audio: @q.question.hasAudio()
      q_type: @q.generator.get('type')

    @$el.find('#leksa_question a.answerlink.text').textfill
      minFontPixels: 18
      maxFontPixels: 36

    @cur_points = @q.generator.get('points')

    @pts_bubble.find('.points').html("+#{@cur_points}")
    @pts_bubble.hide()

    #
    # Register answer click handlers
    @$el.find('#leksa_question a.answerlink').click (evt) =>
      if @auto_advance
        return false
      else
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
        @q.question.playAudio
          finished: app.leksaView.soundFinished

    # Delay first sound playing as leksa page renders
    if @pregenerated?
      setTimeout(playFirst, 1500)
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
      # TODO: don't reinitialize countdown if one is already going for this
      # question
      @current_audio = @q.question.playAudio
        finished: app.leksaView.soundFinished
      return false

    return true

  countdownPoints: () ->
    # these parts need to be written with reference to app, because setting
    # them as an interval or timeout breaks scope
    if app.leksaView.cur_points > 5
      app.leksaView.cur_points -= 5
      app.leksaView.pts_bubble.find('.points').html("+#{app.leksaView.cur_points}")
      if app.debug
        console.log "available points: #{app.leksaView.cur_points}"

    # need to tail call or something with setTimeout
    app.wait_handler = setTimeout(app.leksaView.countdownPoints, 1000)
    return false

  soundFinished: () ->
    # Begin point degrading after the sound has finished
    if app.debug
      console.log "View got sound finished."
    app.leksaView.countdownPoints()
    return false

  render: ->
    # if user ends up on front page due to error and comes back here, events
    # are not registered
    # Render template and insert a question
    if app.wait_handler?
      console.log "Clearing old wait handler"
      clearTimeout app.wait_handler

    @$el.html @template {
      leksa_category: @attributes.leksa_category
    }

    @pts_bubble = @$el.find('#points_for_question')
    @pts_bubble.hide()

    @renderQuestion()

    @first = true

    return this
