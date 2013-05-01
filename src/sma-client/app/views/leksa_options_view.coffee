
module.exports = class LeksaOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  className: 'hello'
  events:
    'click #save-options': 'saveOptions'

  saveOptions: (evt) ->
    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false
       
    _data = @$el.find('select[name="data-storage"]')
    _audio = @$el.find('select[name="play-audio"]')
    # $('#current_level input[checked]').val()

    enable_cache = toBool _data.slider().val()
    enable_audio = toBool _audio.slider().val()

    new_opts = {
      'enable_cache': enable_cache
      'enable_audio': enable_audio
    }

    DSt.set('app_options', new_opts)

    app.options = new_opts

  template: require './templates/leksa_options_view'

  render: ->
    @$el.html @template

    ## if app.options?
    ##   _set = @$el.find('#semantic_set fieldset')
    ##   _level = @$el.find('#current_level fieldset')
    ##   _set.val(
    ##       app.options.enable_cache.toString()
    ##   )
    ##   _level.val(
    ##       app.options.enable_audio.toString()
    ##   )
    ##   # _cache.slider('refresh')
    ##   # _audio.slider('refresh')

    this

