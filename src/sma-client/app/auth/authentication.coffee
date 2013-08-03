LoginTemplate = require '/views/templates/login_modal'

module.exports = class Authenticator

  hide_authentication_popup: (el) ->
    el.find('#loginPopup').hide()

  render_authentication_popup: (el, opts = {}) ->
    # TODO: mutiple insertions in different elements will result in two of the
    # same IDs, fix
    auth_popup_form_submit = (event) =>
      # TODO: disable form
      console.log "submitted"
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
        console.log "auth.create_user: fail"
        opts.fail(response) if opts.fail

    _create_user.success (response) =>
        console.log "auth.create_user: success"
        opts.success(response) if opts.success

    _create_user.always (response) =>
        console.log "auth.create_user: always"
        opts.always(response) if opts.always

    return opts

  logout: (opts = {}) ->
    logout_request = $.ajax
      type: "GET"
      url: "/user/logout/"
      xhrFields:
        withCredentials: true

    logout_request.fail (resp) ->
      console.log "fail"
      console.log JSON.parse resp.responseText
      app.user = null
      opts.fail(resp) if opts.fail

    logout_request.success (data, textStatus, jqXHR) ->
      console.log "Should be logged out..."
      test_authed_request = $.getJSON('/user/data/log')
      test_authed_request.success (resp) ->
        console.log resp
      # TODO: app.user = something
      app.user = false
      opts.success(data, textStatus, jqXHR) if opts.success

  login: (opts = {}) ->
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
      console.log "fail"
      console.log JSON.parse resp.responseText
      app.user = null
      opts.fail(resp) if opts.fail

    login_request.success (data, textStatus, jqXHR) ->
      console.log "Should be logged in..."
      test_authed_request = $.getJSON('/user/data/log')
      test_authed_request.success (resp) ->
        console.log resp

      app.user = {
        username: data.user.username
        email: data.user.email
      }

      # console.log "User logged in, syncing options"
      # app.options.storage.sync.pull({
      #   success: (data) ->
      #     console.log "storage.success"
      #     console.log data
      #     console.log app.options.attributes
      # })

      # TODO: why isn't this creating objects? It's fetching them properly.
      #       same result with .full()
      #
      # TODO: sync options as well.
      #
      console.log "User logged in, syncing progression"
      app.leksaUserProgression.storage.sync.pull({
        success: (data) ->
          console.log "userlog.success"
          console.log data
          console.log app.options.attributes
      })

      app.options.storage.sync.full({
        success: (data) ->
          console.log "storage.full.success"
          console.log data
          console.log app.options.models
      })

      opts.success(data, textStatus, jqXHR) if opts.success
