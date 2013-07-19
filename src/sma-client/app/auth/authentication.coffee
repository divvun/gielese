module.exports = class Authenticator

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
    login_request = $.ajax
      type: "GET"
      url: "/user/logout/"
      xhrFields:
        withCredentials: true

    login_request.fail (resp) ->
        console.log "fail"
        console.log JSON.parse resp.responseText
        app.user = null
        opts.fail(data, textStatus, jqXHR) if opts.fail

    login_request.success (data, textStatus, jqXHR) ->
        console.log "Should be logged out..."
        test_authed_request = $.getJSON('/user/data/log')
        test_authed_request.success (resp) ->
          console.log resp
        app.user = null
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
        app.user = true

        opts.success(data, textStatus, jqXHR) if opts.success
