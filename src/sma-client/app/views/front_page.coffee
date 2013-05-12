# A front page view to ask users introductory questions about their experience.
# Once this is set, need to skip this on further loads.

module.exports = class FrontPage extends Backbone.View

  events:
    "click #next": "nextQuestion"
    "submit #user": "userForm"
    # TODO: wrong element?
    # "click input[value='sma']:visible": "userSelectsSma"
    # "select input[value='sma']:visible": "userSelectsSma"
    # TODO: user selects sma 

  userForm: (event) ->
    # display loading
    #

    un = $ "#user #un"
    pw = $ "#user #pw"

    # ajax call to check that user can be created
    # if fail, display errors
    # if success, store username, api key, etc., continue

    return false

  userSelectsSma: (event) ->
    console.log "omg"
    $('#help_language').fadeOut()
    $('#auxiliary_language').fadeIn()
    return false
  
  updateProgress: (count) ->
    @$el.find('#progressbar').progressbar({value: count})
    if count == 100
      # TODO, commented out for demoing
      # DSt.set('gielese-configured', true)
      window.app.router.index()


  storeCurrentVisibleSetting: (current) ->
    # user global settings object?
    # TODO: check if in subquestion block?
    window.current = current
    console.log current

    fieldset = current.find('fieldset')

    if not fieldset
      return false

    checked_setting = current.find('fieldset input[type="radio"]:checked')
    setting_target = fieldset.attr('data-setting')
    setting_value = checked_setting.val()

    # may not be subquestion, also 
    next_subquestion = current.next('.sub_question_block')[0]
    allow_next = checked_setting.attr('data-subquestion')

    if next_subquestion and allow_next
      current.hide()
      $(next_subquestion).show()
      @questions_answered += 1
      @total_questions += 1
      @updateProgress((@questions_answered/@total_questions)*100)
      return true

    # Detect subsetting, return true if pass

    return false

  nextQuestion: (event) ->
    # When the last one arrives, begin! also store that settings were viewed
    # TODO: shake next on no-answer
    @updateProgress((@questions_answered/@total_questions)*100)

    current = $ """ .question_blocks 
                    .question_block:visible 
                    .sub_question_block:visible
                """

    next = $('.question_blocks .question_block:visible')
           .next('.question_block')[0]

    subquestion = @storeCurrentVisibleSetting(current)

    if subquestion
      next_subquestion = true
      return false

    if next
      current.hide()
      $(next).show()
      @questions_answered += 1
      @updateProgress((@questions_answered/@total_questions)*100)
    else
      window.app.router.mainMenu()

    return false

  id: "frontPage"

  template: require './templates/front_page'

  render: ->
    @total_questions = 2
    @questions_answered = 0
    @process_complete = false

    @$el.html @template
    @updateProgress((@questions_answered/@total_questions)*100)
    this

