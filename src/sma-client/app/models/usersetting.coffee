module.exports = class UserSetting extends Backbone.Model
  # For storing user configuration stuff and syncing with the server, keep it
  # simple.

  url: "/user/settings/"

  defaults:
    setting_key: false
    setting_value: false

  # Attributes to not push to server
  do_not_push: [
    "sid"
    "dirty"
  ]

  initialize: () ->
    @set('sid', 'new')
    @set('dirty', true)
    @set('_id', @cid)

  toJSON: (options) ->
    # TODO: setting to keep everything?
    attrs = @attributes
    for i in @do_not_push
      delete attrs[i]
    return _.clone(attrs)


