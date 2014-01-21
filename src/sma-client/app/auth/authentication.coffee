LoginTemplate = require '/views/users/templates/login_modal'

module.exports = class Authenticator

  hide_authentication_popup: (el) ->
    el.find('#loginPopup').hide()

  render_authentication_popup: (el, opts = {}) ->
    # TODO: mutiple insertions in different elements will result in two of the
    # same IDs, fix
    auth_popup_form_submit = (event) =>
      # TODO: disable form
      if app.debug
        console.log "Authenticator.login: submitted"
      el.find('#loginPopup #loading').fadeIn()
  
      @login
        username: el.find('#loginPopup #un').val()
        password: el.find('#loginPopup #pw').val()
        success: (data, textStatus, jqXHR) =>
          el.find('#loginPopup #loading').fadeOut()
          el.find('#loginPopup #success').fadeIn()
          opts.success(data, textStatus, jqXHR) if opts.success
        fail: (resp) =>
          el.find('#loginPopup #loading').fadeOut()
          el.find('#loginPopup #fail').fadeIn()
          el.find('#loginPopup #login_error').html resp.error
          opts.fail() if opts.fail
      
      return false

    resetState = () ->
      # TODO: enable form
      el.find('#loginPopup #loading').hide()
      el.find('#loginPopup #success').hide()
      el.find('#loginPopup #fail').hide()
      el.find('#loginPopup #pw').val('')

    if $('#loginPopup').length == 0
      login_template = LoginTemplate()
      el.append(login_template)
      
      # Rerender elements
      el.find('#loginPopup').trigger('create')

      # el.find('#loginPopup input').textinput()
      # el.find('#loginPopup button').button()
      # el.find('#loginPopup .close_modal').button()
      
      # Events
      el.find('#loginPopup form').submit auth_popup_form_submit
      el.find('#loginPopup .close_modal').click (e) ->
        popup = el.find("#loginPopup")
        popup.popup().hide().popup('close')

    # Show it
    popup = el.find("#loginPopup")
    resetState()
    popup.popup().show().popup('open')

    return false

  create_user: (opts = {}) ->
    data =
      username: opts.username
      email:    opts.email
      password: opts.password
      
    _create_user = $.post("/user/create/", data)

    _create_user.fail (response) =>
        if app.debug
          console.log "auth.create_user: fail"
        opts.fail(response) if opts.fail

    _create_user.success (response) =>
        if app.debug
          console.log "auth.create_user: success"
        opts.success(response) if opts.success

    _create_user.always (response) =>
        if app.debug
          console.log "auth.create_user: always"
        opts.always(response) if opts.always

    return opts

  logout: (opts = {}) ->
    logout_request = $.ajax
      type: "GET"
      url: "/user/logout/"
      xhrFields:
        withCredentials: true

    # TODO: sync everything left over in user collections

    logout_request.fail (resp) ->
      # TODO: post log to server
      console.log "Authenticator.logout.logout_request.fail: fail"
      console.log JSON.parse resp.responseText
      app.user = null
      opts.fail(resp) if opts.fail

    logout_request.success (data, textStatus, jqXHR) =>
      app.user = false
      if app.debug
        console.log "Authenticator.logout.logout_request.success"
      @clearUserData()

      opts.success(data, textStatus, jqXHR) if opts.success

  clearUserData: ->
    if app.debug
      console.log "Authenticator.clearUserData()"

    # exception for login-details
    deets = DSt.get('login-details')
    window.localStorage.clear()
    app.options.reset()
    app.userprogression.reset()
    deets = DSt.set('login-details', deets)

    if app.debug
      console.log "Cleared user data."
      console.log [ app.userprogression.length
                  , app.options.length, window.localStorage
                  ]

  forgot: (opts = {}) ->
    data = {}

    if opts.email
      data.email_address = opts.email

    if opts.username
      data.username = opts.username

    forgotten_request = $.ajax
      type: "POST"
      url: "/user/forgot/"
      data: data
      xhrFields:
        withCredentials: true

    forgotten_request.fail (resp) =>
      # TODO: log to server?
      console.log "fail"
      console.log JSON.parse resp.responseText
      app.user = null
      opts.fail(resp) if opts.fail

    forgotten_request.success (data, textStatus, jqXHR) ->
      if app.debug
        console.log "Authenticator.login.forgot: Request for token successfully submitted ..."
      opts.success() if opts.success

    forgotten_request.complete () =>
      opts.complete() if opts.complete

  # change_password: (opts = {}) ->
  #   data =
  #     new_password: new_password

  #   if opts.forgotten_token?
  #     data.forgotten_token = forgotten_token

  #   if opts.old_password?
  #     data.old_password = old_password

  #   change_request = $.ajax
  #     type: "POST"
  #     url: "/user/change/"
  #     data: data
  #     xhrFields:
  #       withCredentials: true

  login: (opts = {}) ->
    # TODO: when to clear user data before login?
    data =
      username: opts.username
      password: opts.password
    
    login_request = $.ajax
      type: "POST"
      url: "/user/login/"
      data: data
      xhrFields:
        withCredentials: true

    login_request.fail (resp) =>
      # TODO: log error to server?
      console.log "fail"
      console.log JSON.parse resp.responseText
      app.user = null
      opts.fail(resp) if opts.fail

    login_request.success (data, textStatus, jqXHR) ->
      if app.debug
        console.log "Authenticator.login.success: Should be logged in..."
      test_authed_request = $.getJSON('/user/data/log')
      test_authed_request.success (resp) ->
        if app.debug
          console.log "Authenticator.login.success.tesst_authed_request: "
          console.log resp

      app.user = {
        username: data.user.username
        email: data.user.email
      }
      opts.success() if opts.success

    login_request.complete () =>

      # TODO: need to chain some of this stuff so that opts.success is only
      # called when everything else is done, or create a separate opts.finished
      # method or something.

      if app.debug
        console.log "User logged in, syncing progression"
      $.when(
        app.userprogression.storage.sync.full({
          success: (data) ->
            if app.debug
              console.log "userlog.full.success"
        }),
        app.options.storage.sync.full({
          success: (data) ->
            if app.debug
              console.log "storage.full.success"
        })
      ).then () =>
        if app.debug
          console.log "all login requests complete"
        opts.success() if opts.success

