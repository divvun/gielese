module.exports = class Authenticator

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

    login_request.success (data, textStatus, jqXHR) ->
        console.log "Should be logged out..."
        test_authed_request = $.getJSON('/user/data/log')
        test_authed_request.success (resp) ->
          console.log resp
        app.user = null

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

    login_request.fail (resp) ->
        console.log "fail"
        console.log JSON.parse resp.responseText
        app.user = null

    login_request.success (data, textStatus, jqXHR) ->
        console.log "Should be logged in..."
        test_authed_request = $.getJSON('/user/data/log')
        test_authed_request.success (resp) ->
          console.log resp
        app.user = true

