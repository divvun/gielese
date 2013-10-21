# A front page view to ask users introductory questions about their experience.
# Once this is set, need to skip this on further loads.

FrontPageTemplate = require './templates/front_page'

module.exports = class FrontPage extends Backbone.View

  id: "frontPage"

  template: FrontPageTemplate

  # NB: some events need to be bound after the template is rendered, because
  # jQuery mobile and Backbone events don't play well together.
  events:
    "submit #user": "userForm"
    "click #displayLogin": "displayLogin"
    "change #create-user-account-c": "displayLogin"
    "click #end a": "begin"
    
    "change input[type='radio']": "changeInput"
    "change [data-subquestion]": "revealSubquestion"
    "change [data-hide-subquestion]": "hideSubquestion"
      
      
  begin: (evt) ->
    DSt.set('gielese-configured', true)

  changeInput: (evt) ->
    console.log evt.target
    fieldset = $(evt.target).parents('fieldset')
    @storeCurrentVisibleSetting fieldset
    return true

  revealSubquestion: (evt) ->
    sub = $(evt.target).attr('data-subquestion')
    @$el.find("##{sub}").slideDown()
    return true

  hideSubquestion: (evt) ->
    sub = $(evt.target).attr('data-hide-subquestion')
    @$el.find("##{sub}").slideUp()
    return true

  displayLogin: ->
    app.auth.render_authentication_popup @$el, {
      success: () =>
        setTimeout(() =>
          app.auth.hide_authentication_popup @$el
          window.location.hash = "#mainMenu"
        , 250)
        # TODO: check if user has configured stuff-- if not (for instance, they
        # created a username and account, but got thrown out of the process for
        # some reason), need to resume for them.
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

  storeCurrentVisibleSetting: (fieldset) ->

    # TODO: user settings model
    checked_setting = fieldset.find('input[type="radio"]:checked')
    setting_target = fieldset.attr('data-setting')
    setting_value = checked_setting.val()

    refresh_template = false

    if setting_target and setting_value
      for key in setting_target.split(',')
        if key == "interface_language"
          refresh_template = true
        app.options.setSetting key, setting_value

    if refresh_template
      setTimeout(@refreshTemplate, 500)

    return true

  refreshTemplate: () =>
    # Refresh the template when language setting is changed
    #

    # TODO: store form values to reload
    DSt.store_form($('form#user')[0])
    @$el.html @template
    $('[data-role=page]').trigger('pagecreate')
    @loadSettings()
    DSt.recall_form($('form#user')[0])

  loadSettings: ->
    help_lang = app.options.getSetting('help_language')
    h_value = "[value=#{help_lang}]"

    resetCheck = (vs, val) ->
      vs.attr('checked', val).checkboxradio().checkboxradio('refresh')

    resetCheck $("#help_language [type=radio]"), false
    resetCheck $("#help_language #{h_value}"), true
    if h_value == 'sma'
      sub = $("#help_language").attr('data-subquestion')
      setTimeout( () ->
        @$el.find("##{sub}").slideDown()
      , 500)

  render: ->
    @total_questions = 2
    @questions_answered = 0
    @process_complete = false

    @$el.html @template

    @loadSettings()

    # Need to bind events here; jQuery mobile creates elements that messes with
    # backbone events.

    this

