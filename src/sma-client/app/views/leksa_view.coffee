
StatTemplate = require 'views/templates/stat_block'

UserLog = require 'models/user_log_entry'
UserProgression = require 'models/user_progression'

# NOTE: some sample data, which will be eventually stored elsewhere

audio_files = {
  "åalkie": "/audio/åalkie AD.wav"
  "ååredæjja": "/audio/ååredæjja AD.wav"
  "åejjie": "/audio/åejjie AD.wav"
  "baenie": "/audio/baenie AD.wav"
  "båetskie": "/audio/båetskie AD.wav"
  "bielkie": "/audio/bielkie AD.wav"
  "gaalloe": "/audio/gaalloe AD.wav"
  "gaetskedh": "/audio/gaetskedh AD.wav"
  "gïete": "/audio/gïete AD.wav"
  "govledh": "/audio/govledh AD.wav"
  "guehpere": "/audio/guehpere AD.wav"
  "haermie": "/audio/haermie AD.wav"
  "hepsedh": "/audio/hepsedh AD.wav"
  "juelkie": "/audio/juelkie AD.wav"
  "kråahpe": "/audio/kråahpe AD.wav"
  "lïhtse": "/audio/lïhtse AD.wav"
  "njaelmie": "/audio/njaelmie AD.wav"
  "njoektjeme": "/audio/njoektjeme AD.wav"
  "njuenie": "/audio/njuenie AD.wav"
  "njulhtjedh": "/audio/njulhtjedh AD.wav"
  "ravve": "/audio/ravve AD.wav"
  "rudtje": "/audio/rudtje AD.wav"
  "searome": "/audio/searome AD.wav"
  "skaavtjoe": "/audio/skaavtjoe AD.wav"
  "soerme": "/audio/soerme AD.wav"
  "steeredh": "/audio/steeredh AD.wav"
  "tjahkashidh": "/audio/tjahkashidh AD.wav"
  "tjåejjie": "/audio/tjåejjie AD.wav"
  "tjelmie": "/audio/tjelmie AD.wav"
  "tjiehtjere": "/audio/tjiehtjere AD.wav"
  "tjuvliestidh": "/audio/tjuvliestidh AD.wav"
  "vaeltedh": "/audio/vaeltedh AD.wav"

  "guelie": "/audio/vaeltedh AD.wav"
}


## ## Storage of concepts in external db?
##
#

# Concepts have a value, and potential semantic values and featural values as
# well as relate to eachother on a many-to-many basis.

# modified extensions for existing sma lexical data

# <tg xml:lang="img">
#   <t color="brown" texture="fuzzy"><![CDATA[/path/to/img.jpg]]>
# </tg>


# <tg xml:lang="lyd">
#   <t gender="fem" age="young"><![CDATA[/path/to/sound.mp3]]>
# </tg>

# Goal is that all of this can be installed in oahpa, or an oahpa-like service,
# and then serialized to JSON server-side, downloaded and installed to concepts
# as the internet connection exists, and as new concepts are updated to the
# external DB.
#

#
##
## ##




# TODO: all of these things will need to be in local database. Also so far
# these are all refreshed when the user navigates away from the page and comes
# back. Some of these will need to be instantiated with the application, or recalled
# from local or external storage.
window.userprogression = new UserProgression()

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
    @logConcept(question, correct_answer_concept, true)
    $('.set_done_options').show()
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
    userprogression.push new UserLog({
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
    @logConcept(question, correct_answer_concept, false)

    return false
    
  renderQuestion: ->
    # Select a question, render it, bind event handlers to each possible
    # answer

    # 
    # Hide the question-end options
    $('.set_done_options').hide()

    # TODO: smooth scroll
    window.scrollTo(0,0)

    #
    # Select a question
    q = _.shuffle(app.questiondb.models)[0]
    #
    # Find the concepts, answers, etc., for the question
    [question, alt_choices, answer] = q.find_concepts(app.conceptdb)
    if not question
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

    #
    # Render the template for the question
    question_block = @question_template {
          question_type: q.get('type')
          question: question
          choices: _.shuffle(alt_choices)
          answer: answer
          render_concept: render_concept
          chunker: arrayChunk
      }
    @$el.find('#leksa_question').html(question_block)

    #
    # Register answer click handlers
    @$el.find('#leksa_question a.answerlink').click (evt) =>
      answerlink = $(evt.target).parents('.answerlink')
      user_input = answerlink.attr('data-word')
      answer_value = answer.get('concept_value')
      if user_input == answer_value
        # If user is correct, stop watching for additional clicks
        @$el.find('#leksa_question a.answerlink').unbind('click').click (evt) ->
          return false
        @correctAnswer(q, answerlink, answer, question)
      else
        @incorrectAnswer(q, answerlink, answer, question)
      #
      # rebind event to null result incase user clicks multiple times
      answerlink.unbind('click').click (evt) -> return false
      return false

    app.router.refreshCurrentPage()

    return true

  updateLogPanel: (entry) ->
    # Collate results from userprogression collection, display them.
    $('#stat_block').html StatTemplate {
        total: userprogression.models.length
        correct: userprogression.totalCorrect()
        concept_progress: userprogression.collateConcepts(app.conceptdb)
    }
  
  render: ->
    # Render template and insert a question
    @$el.html @template

    @renderQuestion()
    # Bind an event to user progression-- TODO: move elsewhere
    userprogression.on('add', @updateLogPanel)
    return this

