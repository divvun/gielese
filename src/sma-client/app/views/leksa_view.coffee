
StatTemplate = require 'views/templates/stat_block'

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


# TODO: all of these things will need to be in local database. Also so far
# these are all refreshed when the user navigates away from the page and comes
# back. Some of these will need to be instantiated with the application, or recalled
# from local or external storage.

# TODO: progression: increase amount of possible answers for individual words from
#       1 - 4


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

  newQuestionSameGroup: (evt) ->
    @renderQuestion()
    return false
  
  correctAnswer: (question, user_input, user_answer_concept, correct_answer_concept) ->
    # Give user feedback that they were correct, and show the set done options.

    $(user_input).addClass('correct')
    usr_msg = $('<a href="#" class="correct usr_msg">Correct</a>')
    $(user_input).parent().append usr_msg
    @logConcept(question, correct_answer_concept, true)
    $('.set_done_options').show()
    fadeUp usr_msg
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

    #
    # Create the log entry in the user progression
    window.app.leksaUserProgression.push new UserLog({
      game_name: "leksa"
      question_concept: concept.get('c_id')
      question_concept_value: concept_name
      question_correct: correct
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
    
  renderQuestion: ->
    # Select a question, render it, bind event handlers to each possible
    # answer

    # 
    # Hide the question-end options
    $('.set_done_options').hide()

    # TODO: smooth scroll
    window.scrollTo(0,0)

    if app.questiondb.length == 0 and app.conceptdb.length == 0
      window.last_error = "Question DB and Concept DB not ready."
      app.router.navigate('error')
    #
    # Select a question
    #
    # Max attempts 5, if cannot generate a question from the template,
    # then skip. The question will be marked as failing, and filtered
    # out of the cycle
    max_tries = 5
    tries = 0
    question_instance = false
    while not question_instance and tries <= max_tries
      functioning_concepts = app.questiondb.models.filter (c) ->
        _fails = c.get('fails')
        if not _fails
          return true
        if _fails and _fails == false
          return false
      q = _.shuffle(functioning_concepts)[0]
      question_instance = q.find_concepts(app.conceptdb, window.app.leksaUserProgression)
      tries += 1

    if not question_instance.question
      question_block = @leksa_error_template({
        error_msg: "A question could not be generated from these parameters"
      })
      @$el.find('#leksa_question').html(question_block)
      return false

    #
    # Some objects for handling concept rendering
    concept_renderers =
      'img': (c) ->
        return "<img class='concept img_concept' src='#{c.get('concept_value')}' />"
      'text': (c) ->
        return "<span class='concept word_concept'>#{c.get('concept_value')}</span>"
    
    render_concept = (_concept) =>
      type = _concept.get('concept_type')
      return concept_renderers[type](_concept)

    audio_enabled = false
    if app.options.enable_audio and 'audio' of question_instance.question.get('media')
      if question_instance.question.get('media').audio.length > 0
        has_audio_file = question_instance.question.get('media').audio[0].path
        if has_audio_file and soundManager.enabled
          audio_enabled = true

    #
    # Render the template for the question
    question_block = @question_template {
          question_type: question_instance.generator.get('type')
          question: question_instance.question
          choices: _.shuffle(question_instance.choices)
          answer: question_instance.answer
          render_concept: render_concept
          chunker: arrayChunk
          audio: audio_enabled
      }
    @$el.find('#leksa_question').html(question_block)

    #
    # Register answer click handlers
    @$el.find('#leksa_question a.answerlink').click (evt) =>
      answerlink = $(evt.target).parents('.answerlink')
      user_input = answerlink.attr('data-word')
      answer_value = question_instance.answer.get('concept_value')
      window.last_user_input = answerlink
      if user_input == answer_value
        # If user is correct, stop watching for additional clicks
        @$el.find('#leksa_question a.answerlink').unbind('click').click (evt) ->
          return false
        @correctAnswer(question_instance.generator, answerlink,
                        question_instance.answer, question_instance.question)
      else
        @incorrectAnswer(question_instance.generator, answerlink,
                           question_instance.answer, question_instance.question)
      #
      # rebind event to null result incase user clicks multiple times
      answerlink.unbind('click').click (evt) -> return false
      return false

    app.router.refreshCurrentPage()
    # play sound once
    # threeSixtyPlayer.init()
    # threeSixtyPlayer.sounds[0].play()

    # NB: Strange bug here. If audio is disabled, and you go to front
    # page to enable and then come back to leksa, clicking next will
    # result in going to home.
    if app.options.enable_audio and 'audio' of question_instance.question.get('media')
      if question_instance.question.get('media').audio.length > 0
        has_audio_file = question_instance.question.get('media').audio[0].path
        if has_audio_file and soundManager.enabled
          soundManager.destroySound("questionSound")
          soundManager.createSound({
          	id: "questionSound"
          	url: "/static#{has_audio_file}"
          })
          playFirst = () ->
            soundManager.play("questionSound")
          # Delay first sound playing as leksa page renders
          if not @first
            setTimeout(playFirst, 1500)
            @first = false
          else
            playFirst()
          @$el.find('#question_play').click () =>
            soundManager.play("questionSound")
            return false
      
    return true

  updateLogPanel: (entry) ->
    # Collate results from window.app.leksaUserProgression collection, display them.
    $('#stat_block').html StatTemplate {
        total: window.app.leksaUserProgression.models.length
        correct: window.app.leksaUserProgression.totalCorrect()
        concept_progress: window.app.leksaUserProgression.collateConcepts(app.conceptdb)
    }
  
  render: ->
    # Render template and insert a question
    @$el.html @template

    @renderQuestion()
    @first = true
    # Bind an event to user progression-- TODO: move elsewhere
    window.app.leksaUserProgression.on('add', @updateLogPanel)
    return this

