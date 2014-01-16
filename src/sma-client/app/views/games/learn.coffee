#
##
## ## Notes and stuff
##
#
#  There is some helpful documentation on potential problems and gotchas with a
#  lot of the javascript problems one might encounter. See `leksa.coffee`.
#
#

LevelCompleted = require './templates/leksa_level_completed'
LeksaConceptTemplate = require '/views/templates/leksa_concept'

LeksaView = require '/views/games/leksa'

#
##
## ##

module.exports = class LearnView extends LeksaView

  events:
    # TODO: test swiping
    'click #menu_next': "newQuestionSameGroup"
    'click .disable_auto_handler': "reset_auto_event"

  id: "leksa"
  auto_advance: true
  level_constraint: (question) -> question.get('level') == 1

  reset_auto_event: () ->
    if app.wait_handler?
      clearTimeout app.wait_handler
    if app.leksaView.auto_advance_handler?
      clearInterval @auto_advance_handler
    if app.leksaView.countdown_handle?
      clearInterval @countdown_handle
    return true

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

    # TODO: ordering
    if @ordering?
      q = app.questiondb.selectQuestion(
        @attributes.leksa_category,
        false,
        @ordering
      )
    else
      q = app.questiondb.selectQuestionByProg(
        @attributes.leksa_category,
        level_constraint,
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

    if not @ordering?
      if app.debug
        console.log "choosing ordering"

      @cat = _.first app.categories.where
        category: @attributes.leksa_category
      concepts = @cat.getConcepts
        language: @q.generator.attributes.filters.to_language
      @ordering = (c.get('concept_value') for c in concepts)
      @ordering = _.shuffle @ordering.filter (c) =>
        c isnt @q.answer.attributes.concept_value

      # @ordering.push "THIS_IS_THE_LAST"
      @ordering.push @q.answer.attributes.concept_value
    else
      last = @ordering.shift(0)
      @ordering.push(last)

    if app.debug
      console.log @ordering

    if not @q.question
      _log_msg = "LearnView.render_question: ungeneratable question in ordering"
      _log_msg += " " + @ordering.join(', ')
      console.log @ordering
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

    # Do not advance
    @$el.find('#leksa_question a.answerlink').click (evt) =>
      return false

    app.router.refreshCurrentPage()

    playFirst = =>
      if app.options.getSetting('enable_audio') and @q.generator.get('sound')
        @playQuestionSound()

    # Delay first sound playing as leksa page renders
    if @pregenerated?
      delete @pregenerated
    else
      if not @first
        app.wait_handler = setTimeout(playFirst, 1500)
        @first = false
      else
        playFirst()

    @$el.find('#question_play').click () =>
      if app.debug?
        console.log "Play:"
        console.log @q.question
      @q.question.playAudio()
      return false

    return true

  playQuestionSound: () ->
    # Play the audio, but periodically poll to see if it's completed
    # if complete, then move on.

    if @preselected_q
      console.log "preselected"
      a = @preselected_q
    else
      a = @q

    window.current_audio = a.question.playAudio()

    checkPosition = () ->
      console.log "polling"
      current_audio = window.current_audio
      if current_audio.position == current_audio.duration or \
         current_audio.position == current_audio.durationEstimate
        app.leksaView.soundFinished()
      else
        setTimeout(checkPosition, 200)

    if current_audio?
      setTimeout(checkPosition, 200)
    else
      app.leksaView.soundFinished()
    
  soundFinished: () ->
    if app.debug
      console.log "View got sound finished."
    app.wait_handler = setTimeout(() =>
      if /leksa/.exec window.location.hash
        app.leksaView.renderQuestion()
      else
        clearTimeout app.wait_handler
        return false
    , 4000)

  render: ->
    # if user ends up on front page due to error and comes back here, events
    # are not registered
    # Render template and insert a question

    @cat = _.first app.categories.where
      category: @attributes.leksa_category

    @$el.html @template {
      leksa_category: @attributes.leksa_category
      category: @cat.attributes.name
    }

    @pts_bubble = @$el.find('#points_for_question')
    @pts_bubble.hide()

    app.leksaView.renderQuestion()

    @first = true

    return this
