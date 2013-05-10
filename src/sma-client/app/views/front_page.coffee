# A front page view to ask users introductory questions about their experience.
# Once this is set, need to skip this on further loads.

module.exports = class FrontPage extends Backbone.View

  events:
    "click #next": "nextQuestion"
    # TODO: wrong element?
    # "click input[value='sma']:visible": "userSelectsSma"
    # "select input[value='sma']:visible": "userSelectsSma"
    # TODO: user selects sma 

  userSelectsSma: (event) ->
    console.log "omg"
    $('#help_language').fadeOut()
    $('#auxiliary_language').fadeIn()
    return false
  
  nextQuestion: (event) ->
    # TODO: save current form option/value, hide and cycle to next.
    #
    # When the last one arrives, begin! also store that settings were viewed
    current = $('.question_blocks .question_block:visible')
    next = $('.question_blocks .question_block:visible').next()[0]
    current.hide()

    if next
      $(next).show()
    else
      # redirect!
      console.log "TODO: redirect"
    return false


  id: "frontPage"

  template: require './templates/front_page'

  render: ->
    @$el.html @template
    this

