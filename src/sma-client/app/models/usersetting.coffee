module.exports = class UserSetting extends Backbone.Model
  # For storing user configuration stuff and syncing with the server, keep it
  # simple.

  url: "/user/settings/"

  defaults:
    setting_key: false
    setting_value: false

  initialize: () ->
    @set('sid', 'new')
    @set('dirty', true)
    @set('_id', @cid)


