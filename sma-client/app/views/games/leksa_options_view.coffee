
module.exports = class LeksaOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  className: 'hello'
  events:
    'click #save-options': 'saveOptions'

  getLevel: () ->
    _level = @$el.find('#current_level input[checked]').val()
    if _level.length == 0
      _level = false

    _level

  getSet: () ->
    _set = @$el.find('#semantic_set input[checked]').val()
    if _set.length == 0
      _set = false

    _set

  saveOptions: (evt) ->
    # TODO: check options, store to app.leksaOptions
    # Then, question generation should use app.leksaOptions if something is set.

    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false
       
    _level = @getLevel()
    _set = @getSet()

    if _level
      app.leksaOptions.current_level = _level

    if _set
      app.leksaOptions.current_set = _set

  template: require './templates/leksa_options_view'

  render: ->
    @$el.html @template

    _level = @getLevel()
    _set = @getSet()

    if _level
      @$el.find("#current_level input[value='#{_level}'").click()

    if _set
      @$el.find("#semantic_set input[value='#{_set}'").click()

    # TODO: app.options.getSetting

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

