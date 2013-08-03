module.exports = class GlobalOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  id: 'global_options'

  # TODO: save when the options are adjusted individually.

  events:
    'click #save-options': 'saveOptions'
    'change #help_language': 'revealSubquestion'
    'change #help_language input': 'selectHelpLang'

  selectHelpLang: (evt) ->
    target_fieldset = $(evt.target).parents('fieldset').attr('data-copy-to')
    target_value = $(evt.target).parents('fieldset').find('input[type="radio"]:checked').val()
    $("[data-setting='#{target_fieldset}']").find("[type='radio']").attr("checked",false).checkboxradio("refresh")
    $("[data-setting='#{target_fieldset}']").find("[value='#{target_value}']").attr("checked",true).checkboxradio("refresh")
    console.log $(evt.target).parents('fieldset').find('input[type="radio"]:checked').val()
    console.log $("[data-setting='#{target_fieldset}']").find('input[type="radio"]:checked').val()
    return true

  revealSubquestion: (evt) ->
    subs = ($(a).attr('data-reveal-subquestion') for a in $('[data-reveal-subquestion]'))
    for a in subs
      $("##{a}").slideUp()
    sub = $(evt.target).attr('data-reveal-subquestion')
    if sub?
      $("##{sub}").slideDown()
    return true
  
  saveOptions: (evt) ->
    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false
       
    _data = @$el.find('select[name="data-storage"]')
    _audio = @$el.find('select[name="play-audio"]')

    enable_cache = toBool _data.slider().val()
    enable_audio = toBool _audio.slider().val()

    interface_language = $("[data-setting='interface_language']").find('input[type="radio"]:checked').val()
    help_language = $("[data-setting='help_language']").find('input[type="radio"]:checked').val()

    # TODO: weird bug with flipping away and coming back, does not reset
    # interface languages
    #
    console.log [enable_cache, enable_audio, interface_language, help_language] # MAKE THIS WORK


    app.options.setSetting('enable_cache', enable_cache)
    app.options.setSetting('enable_audio', enable_audio)
    app.options.setSetting('interface_language', interface_language)
    app.options.setSetting('help_language', help_language)

  template: require './templates/global_options'

  reloadSettings: ->
    _cache = @$el.find('select[name="data-storage"]')
    _audio = @$el.find('select[name="play-audio"]')

    uil = app.options.getSetting('interface_language')
    hl  = app.options.getSetting('help_language')

    # NB: ISOs are stored in three-char format here, so no need to convert to
    # read and save in storage
    #
    _ui = @$el.find("[data-setting='interface_language'] input[value='#{uil}']")
    _hl = @$el.find("[data-setting='help_language'] input[value='#{hl}']")

    _cache.val(
        app.options.getSetting('enable_cache').toString()
    )

    _audio.val(
        app.options.getSetting('enable_audio').toString()
    )

    _ui.attr("checked",true)
    _hl.attr("checked",true)

    # TODO: sync offline, or in localstorage

  render: ->
    @$el.html @template

    @reloadSettings()

    # TODO: events for some reason aren't reregistered when returning to this
    # view.
    console.log "render"

