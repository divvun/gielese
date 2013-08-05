# A front page view to ask users introductory questions about their experience.
# Once this is set, need to skip this on further loads.

module.exports = class FrontPage extends Backbone.View

  # NB: some events need to be bound after the template is rendered, because
  # jQuery mobile and Backbone events don't play well together.
  events:
    "submit #user": "userForm"
    "click #displayLogin": "displayLogin"

  # TODO: action for after login?
  displayLogin: ->
    app.auth.render_authentication_popup @$el, {
      success: () =>
        setTimeout(() =>
          app.auth.hide_authentication_popup @$el
        , 250)
        # TODO: check if user has configured stuff-- if not (for instance, they
        # created a username and account, but got thrown out of the process for
        # some reason), need to resume for them.
        #
    }
    return false

  hideLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('hide')
      clearInterval(interval)
    ,1)
    return false

  showLoading: (txt) ->
    interval = setInterval(() =>
      $.mobile.loading('show', {
        text: txt,
        textVisible: true,
        theme: 'a',
        html: ""
      })
      clearInterval(interval)
    ,1)
    return false

  userForm: (event) ->
    # display loading
    #
    @showLoading("Submitting...")

    # TODO: client-side validation?
    #
    username = $("#user #un").val()
    password = $("#user #pw").val()

    opts =
      username: $("#user #un").val()
      email:    $("#user #em").val()
      password: $("#user #pw").val()

    # TODO: maybe submit json instead? do something so it can't be sniffed?
    #

    opts.fail = (resp) =>
      error_json = JSON.parse(resp.responseText)
      console.log "fail2"
      fields = error_json.reasons
      $("form#user input").removeClass("error")
      $("form#user span.error").remove()

      # Can't rely on schematics to return consistent data. Sometimes this is
      # a list, sometimes an Object
      if fields.length?
        # Append errors to form
        for error in fields
          error_msg = $("<span class='error'>")
          error_msg.html(error)
          $("form#user .form_fields").append(error_msg)
      else
        # Highlight fields that have errors
        for key, error of fields
          input = $("input[name=#{key}]")
          input.addClass("error")
          fieldset = input.parents('fieldset')

          error_msg = $("<span class='error'>")
          error_msg.html(error.join(', '))
          fieldset.append error_msg

    opts.success = (resp) =>
      console.log "success2"
      console.log "you were successful, but this doesn't work yet"
      app.auth.login({
      	username: username
      	password: password
      	success: () =>
          $("#loginform_subsub").hide()
          $("#loginform_success").show()
      })
      # TODO: authenticate created user, and show feedback that this is going on

    @$el.find('#fakeSubmit').click (evt) ->
      $("#loginform_subsub").hide()
      $("#loginform_success").show()

    opts.always = (resp) =>
      console.log "always2"
      setTimeout(@hideLoading, 500)

    create_user = app.auth.create_user(opts)

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
      # TODO: change this to be whether user has authed 
      DSt.set('gielese-configured', true)
      if app.user
        app.options.storage.sync.push()
      window.app.router.index()


  storeCurrentVisibleSetting: (current) ->
    # TODO: check if in subquestion block?
    window.current = current
    console.log current

    fieldset = current.find('fieldset')

    if not fieldset
      return false

    # TODO: user settings model
    checked_setting = current.find('fieldset input[type="radio"]:checked')
    setting_target = fieldset.attr('data-setting')
    setting_value = checked_setting.val()

    if setting_target and setting_value
      for key in setting_target.split(',')
        app.options.setSetting(key, setting_value)

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

  nextQuestion: (event) =>
    # When the last one arrives, begin! also store that settings were viewed
    # TODO: shake next on no-answer
    @updateProgress((@questions_answered/@total_questions)*100)

    current = $ """ .question_blocks 
                    .question_block:visible 
                    .sub_question_block:visible
                """

    last = $ """ .question_blocks 
                 .question_block:last
             """

    if current == last
      next = false
    else
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
      if app.user
        app.options.storage.sync.push()
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

    # Need to bind events here; jQuery mobile creates elements that messes with
    # backbone events.
    @$el.find('.nextSection').bind('click', @nextQuestion)

    this

