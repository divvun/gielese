LevelCompleted = require './templates/leksa_level_completed'
LeksaConceptTemplate = require '/views/templates/leksa_concept'

LeksaView = require '/views/games/leksa'

#
##
## ##

fadeUp = (elem) ->
  elem.fadeOut(1500)
    .queue (nxt) ->
      $(this).remove()
      nxt()
  return false

module.exports = class LearnView extends LeksaView

  id: "leksa"
  auto_advance: true
  level_constraint: (question) -> question.get('level') == 1

  # # #
  # # #  Question rendering
  # # #

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

    _repeats = @q.generator.get('repetitions')
    if _repeats == 0
      _repeats = 1
    else
      _repeats += 1

    if not @q.question
      _log_msg = "LearnView.render_question: ungeneratable question - "
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

    countdownPoints = (evt) =>
      if @cur_points > 5
        @cur_points -= 5
        if app.debug
          console.log "available points: #{@cur_points}"

    @countdown_handle = setInterval(countdownPoints, 1000)

    app.router.refreshCurrentPage()

    playFirst = =>
      if app.options.getSetting('enable_audio') and @q.generator.get('sound')
        @q.question.playAudio
          finished: app.leksaView.soundFinished

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
      @current_audio = @q.question.playAudio
        finished: app.leksaView.soundFinished
      return false

    return true

  soundFinished: () ->
    if app.debug
      console.log "View got sound finished."
    setTimeout(() ->
      app.leksaView.renderQuestion()
    , 4000)

  render: ->
    # if user ends up on front page due to error and comes back here, events
    # are not registered
    # Render template and insert a question

    @$el.html @template {
      leksa_category: @attributes.leksa_category
    }

    @pts_bubble = @$el.find('#points_for_question')
    @pts_bubble.hide()

    app.leksaView.renderQuestion()

    @first = true

    return this
