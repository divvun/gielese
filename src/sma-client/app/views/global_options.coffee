module.exports = class GlobalOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  id: 'global_options'

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

    new_opts = {
      'enable_cache': enable_cache
      'enable_audio': enable_audio
    }

    DSt.set('app_options', new_opts)

    app.options = new_opts

  template: require './templates/global_options'

  render: ->
    @$el.html @template

    if app.options?
      _cache = @$el.find('select[name="data-storage"]')
      _audio = @$el.find('select[name="play-audio"]')
      _cache.val(
          app.options.enable_cache.toString()
      )
      _audio.val(
          app.options.enable_audio.toString()
      )
      # _cache.slider('refresh')
      # _audio.slider('refresh')

    this

