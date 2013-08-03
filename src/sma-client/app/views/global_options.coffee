module.exports = class GlobalOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  id: 'global_options'

  # TODO: save when the options are adjusted individually.

  events:
    'click #save-options': 'saveOptions'

  saveOptions: (evt) ->
    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false
       
    _data = @$el.find('select[name="data-storage"]')
    _audio = @$el.find('select[name="play-audio"]')

    enable_cache = toBool _data.slider().val()
    enable_audio = toBool _audio.slider().val()

    app.options.setSetting('enable_cache', enable_cache)
    app.options.setSetting('enable_audio', enable_audio)

  template: require './templates/global_options'

  render: ->
    @$el.html @template

    if app.options?
      _cache = @$el.find('select[name="data-storage"]')
      _audio = @$el.find('select[name="play-audio"]')

      _cache.val(
          app.options.getSetting('enable_cache').toString()
      )
      _audio.val(
          app.options.getSetting('enable_audio').toString()
      )

      # _cache.slider('refresh')
      # _audio.slider('refresh')

    this

