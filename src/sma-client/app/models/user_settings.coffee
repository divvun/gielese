# TODO: problem - syncing one model outside of a collection doesn't quite work
#       so well - requires creating methods to make sure backbone-offline
#       doesn't fail when expecting a collection. how does backbone-offline
#       prefer to do this? 
#

UserSetting = require 'models/usersetting'

module.exports = class UserSettings extends Backbone.Collection
  # For storing user configuration stuff and syncing with the server, keep it
  # simple.

  url: "/user/settings/"

  model: UserSetting

  getSetting: (setting) ->
    setting = @where({setting_key: setting})
    return setting[0].get('setting_value')

  setSetting: (key, val) ->
    setting = @where({setting_key: key})

    if setting.length > 0
      @remove(setting)

    new_setting = @create({setting_key: key, setting_value: val})
    new_setting.set('dirty', true)
    # TODO: full sync? 
    return new_setting

  setDefaults: (opts) ->
    for k, v of opts
      @setSetting(k, v)

  parse: (response, opts) ->
    return response.settings

  initialize: () ->
    @storage = new Offline.Storage('user-settings', @)

    # set after the user successfully authenticates
    # if app.has_user and navigator.onLine
    #   @fetch()

      # parse: (resp) ->
      #   console.log "UserSettings.parse"
      #   console.log resp
      #   return resp.data

# TODO: sync methods
# TODO: call something to refresh settings when a login happens.

