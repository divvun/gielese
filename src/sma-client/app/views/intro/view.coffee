# A front page view to ask users introductory questions about their experience.
# Once this is set, need to skip this on further loads.

FrontPageTemplate = require './templates/front_page'
LoginErrorTemplate = require '/views/users/templates/login_error_modal'

module.exports = class FrontPage extends Backbone.View

  id: "frontPage"

  template: FrontPageTemplate

  # NB: some events need to be bound after the template is rendered, because
  # jQuery mobile and Backbone events don't play well together.
  events:
    "submit #user": "userForm"
    "click #submit": "userForm"

    "click #displayLogin": "displayLogin"
    "change #create-user-account-c": "displayLogin"
    "click #end a": "begin"

    "click #help_language [type='button']": "changeLanguage"
    "change #help_language [type='button']": "changeLanguage"
    "change #create_account [data-subquestion]": "revealUser"
    "change #create_account [data-hide-subquestion]": "hideUser"

  begin: (evt) ->
    DSt.set('gielese-configured', true)

  changeLanguage: (evt) ->
    anon = DSt.get('anonymous_selected')
    if anon
      @language_switched = true
    target_btn = $(evt.target).parents('[type="button"]')

    active = 'b'
    inactive = 'a'

    fieldset = $(evt.target).parents('fieldset')

    @storeCurrentVisibleSetting fieldset, target_btn

    return true

  revealUser: (evt) ->
    sub = $(evt.target).attr('data-subquestion')
    @$el.find("##{sub}").slideDown()
    $('.login_text').show()
    $('.begin_text').hide()
    DSt.set('anonymous_selected', false)
    return true

  hideUser: (evt) ->
    if app.user
      app.auth.logout()
    sub = $(evt.target).attr('data-hide-subquestion')
    @$el.find("##{sub}").slideUp()
    $('.login_text').hide()
    $('.begin_text').show()
    DSt.set('anonymous_selected', true)
    $('#account_exists').hide()
    $('#account_created').hide()
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

  storeForm: () ->
    # This is different from the DSt.store_form method, intended for storing
    # stuff between sessions.
    #
    form_data =
      username: @$el.find("#user #un").val()
      email:    @$el.find("#user #em").val()
      password: @$el.find("#user #pw").val()
    DSt.set('login-details', form_data)

  recallForm: () ->
    # TODO: access token

    ds = DSt.get('login-details')
    if ds
      @$el.find("#user #un").val ds.username
      @$el.find("#user #em").val ds.email
      @$el.find("#user #pw").val ds.password
    return true

  userForm: (event) ->
    # display loading
    #
    @showLoading("Submitting...")

    # TODO: client-side validation?
    #
    username = $("#user #un").val()
    password = $("#user #pw").val()

    create_account_opts =
      username: $("#user #un").val()
      email:    $("#user #em").val()
      password: $("#user #pw").val()

    login_account_opts =
      username: $("#user #un").val()
      email:    $("#user #em").val()
      password: $("#user #pw").val()

    # TODO: maybe submit json instead? do something so it can't be sniffed?
    #

    # TODO: check user first

    create_account_opts.fail = (resp) =>
      error_json = JSON.parse(resp.responseText)
      console.log "fail2"
      fields = error_json.reasons
      console.log error_json
      $("form#user input").removeClass("error")
      $("form#user span.error").remove()
      $("form .grouped_field.error").removeClass("error")

      # Can't rely on schematics to return consistent data. Sometimes this is
      # a list, sometimes an Object
      console.log fields
      if fields
        # Append errors to form
        for fieldname, error of fields
          console.log error
          if 'exists' in error
            @show_login_error(@_LOGIN_ACCOUNT_ERROR_EXISTS, true, username)
            continue
          error_msg = $("<span class='error'>#{error}</span>")
          @$el.find("form#user .form_fields").append(error_msg)
          console.log $("form#user .form_fields")

        # Highlight fields that have errors
        for key, error of fields
          input = $("input[name=#{key}]")
          input.addClass("error")
          fieldset = input.parents('.grouped_field')
          fieldset.addClass('error')

          error_msg = $("<span class='error'>")
          error_msg.html(error.join(', '))
          # fieldset.append error_msg

    create_account_opts.success = (resp) =>
      console.log "success2"
      console.log "you were successful, but this doesn't work yet"
      app.auth.login({
        username: username
        password: password
        success: () =>
          setTimeout(@hideLoading, 500)
          $('.login_text').hide()
          $('.begin_text').show()
          $('#loginform_subsub').slideUp()
          $('#account_created').show()
          # TODO: store form to another DSt variable.
          DSt.store_form(app.frontPage.form[0])
      })
      # TODO: authenticate created user, and show feedback that this is going on

    @$el.find('#fakeSubmit').click (evt) ->
      $("#loginform_subsub").slideUp()
      $("#loginform_success").show()

    create_account_opts.always = (resp) =>
      setTimeout(@hideLoading, 500)

    login_account_opts.fail = (resp) =>
      $('#account_exists').hide()
      create_user = app.auth.create_user(create_account_opts)
      setTimeout(@hideLoading, 500)

    login_account_opts.success = (resp) =>
      setTimeout(@hideLoading, 500)
      if app.user
        app.frontPage.storeForm()
        $("#loginform_success").show()
        $('#account_created').hide()
        $('#account_exists').show()
        $('#loginform_subsub').slideUp()
        $('.login_text').hide()
        $('.begin_text').show()

    login_result = app.auth.login(login_account_opts)

    # ajax call to check that user can be created
    # if fail, display errors
    # if success, store username, api key, etc., continue

    return false

  storeCurrentVisibleSetting: (fieldset, btn) ->

    # TODO: user settings model
    checked_setting = fieldset.find('input[type="radio"]:checked')
    setting_target = fieldset.attr('data-setting')
    setting_value = btn.attr('data-value')

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
    if @language_switched?
      console.log "rendering with switched lang"
      hide_form = true
    else
      hide_form = false

    @$el.html @template {
      hide_form: hide_form
    }
    delete @language_switched
    $('[data-role=page]').trigger('pagecreate')
    @loadSettings()
    DSt.recall_form($('form#user')[0])

  loadSettings: ->
    help_lang = app.options.getSetting('help_language')
    h_value = "[data-value=#{help_lang}]"

    active = 'b'
    inactive = 'a'

    resetCheck = (vs, val) ->
      vs.attr('data-theme', val)

    anon = DSt.get('anonymous_selected')
    if anon
      $('#user_account_block').slideUp()

      $('#create-user-account-b').attr('checked', true)
                                 .checkboxradio('refresh')

      $('#create-user-account-a').attr('checked', false)
                                 .checkboxradio('refresh')

      $('.login_text').hide()
      $('.begin_text').show()

    if app.user
      $('#user_account_block').slideUp()

      $('#create-user-account-b').attr('checked', false)
                                 .checkboxradio('refresh')

      $('#create-user-account-a').attr('checked', true)
                                 .checkboxradio('refresh')

      $('.login_text').hide()
      $('.begin_text').show()
      $('#account_exists').show()
    
  show_login_error: (msg, forgotten=false, username=false, try_again=true) ->
    if @login_error_popup?
      @login_error_popup.remove()

    login_template = LoginErrorTemplate
      error_msg: msg
      forgotten: forgotten
      try_again: try_again

    @$el.append(login_template)

    @login_error_popup = @$el.find('#loginErrorPopup')
    @login_error_popup.trigger('create')
    @login_error_popup.popup().show().popup('open')

    if forgotten
      @login_error_popup.find('a#forget_button').click (e) =>

        if app.debug
          console.log "forgot click evt"
          
        @login_error_popup.popup().popup('close')

        app.auth.forgot
          username: username
          success: () =>
            if app.debug
              console.log "success"
            app.frontPage.cur_msg = @_LOGIN_ACCOUNT_CHECK_EMAIL
            setTimeout(() ->
              app.frontPage.show_login_error(
                app.frontPage.cur_msg, false, false, false)
            , 500)
          fail: () =>
            if app.debug
              console.log "fail"
            app.frontPage.cur_msg = @_LOGIN_ACCOUNT_NETWORK_ERROR
            setTimeout(() ->
              app.frontPage.show_login_error(
                app.frontPage.cur_msg, true, username)
            , 500)

    return


  render: ->
    @total_questions = 2
    @questions_answered = 0
    @process_complete = false

    if @language_switched?
      console.log "rendering with switched lang"
      hide_form = true
    else
      hide_form = false

    @$el.html @template {
      hide_form: hide_form
    }

    @form = @$el.find('form')

    delete @language_switched

    _FORGET = gettext.gettext "Did you forget your password?"
    _EMAIL = gettext.gettext "Check your email!"
    _NETWORK = gettext.gettext "Check your network connection and try again"
    @_LOGIN_ACCOUNT_ERROR_EXISTS = _FORGET
    @_LOGIN_ACCOUNT_CHECK_EMAIL = _EMAIL
    @_LOGIN_ACCOUNT_NETWORK_ERROR = _NETWORK

    # Initialize error template

    @loadSettings()
    
    @recallForm()

    # Need to bind events here; jQuery mobile creates elements that messes with
    # backbone events.

    this

