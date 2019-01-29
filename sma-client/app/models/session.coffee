module.exports = class Session extends Backbone.Model
  # http://whatcodecraves.com/articles/2012/01/11/backbonejs-sessions-and-authentication
  defaults:
    access_token: null,
    user_id: null

  initialize: ->
    @load()

  authenticated: ->
    Boolean(@get("access_token"))

  # Saves session information to cookie
  save: (auth_hash)->
    $.cookie('user_id', auth_hash.id)
    $.cookie('access_token', auth_hash.access_token)

  # Loads session information from cookie
  load: ->
    @set
      user_id: $.cookie('user_id')
      access_token: $.cookie('access_token')

