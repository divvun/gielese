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

  # NB: currently only used for getting settings, not actually automatically
  # populated on instantiation
  default_setting_values:
    enable_cache: false
    enable_audio: true
    interface_language: 'nob'
    help_language: 'nob'

  getSetting: (setting) ->
    s = @where({setting_key: setting})
    if s.length > 0
      return s[0].get('setting_value')
    else
      val = @default_setting_values[setting]
      if val?
        new_s = @setSetting(setting, val)
        return val
    return null

  setSettings: (values, opts = {}) ->
    @setSetting k, v for k, v of values
    if opts.store?
      @storage.sync.push()

  setSetting: (key, val) ->
    setting = @where({setting_key: key})

    if setting.length > 0
      @remove(setting)

    new_setting = @create({setting_key: key, setting_value: val})
    new_setting.set('dirty', true)
    # TODO: full sync? 
    return new_setting

  setDefaults: (opts) ->
    @setSetting k, v  for k, v of opts

  parse: (response, opts) ->
    return response.settings

  initialize: () ->
    @storage = new Offline.Storage('user-settings', @)
    if not app.user
      @setDefaults @default_setting_values

    # set after the user successfully authenticates
    # if app.has_user and navigator.onLine
    #   @fetch()

      # parse: (resp) ->
      #   console.log "UserSettings.parse"
      #   console.log resp
      #   return resp.data

# TODO: sync methods
# TODO: call something to refresh settings when a login happens.

