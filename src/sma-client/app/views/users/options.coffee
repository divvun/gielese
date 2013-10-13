OptionsTemplate = require './templates/options'

module.exports = class GlobalOptionsView extends Backbone.View

  # ? Multiple different manifests depending on what user wants to
  # store?
  id: 'global_options'

  # TODO: save when the options are adjusted individually.

  events:
    'click #save-options': 'saveOptions'
    'change #help_language': 'revealSubquestion'
    'change #help_language input': 'selectHelpLang'
    'change #help_language_2 input': 'saveOptions'
    'change #offline_fieldset select': 'saveOptions'
    'change #audio_fieldset select': 'saveOptions'

  selectHelpLang: (evt) ->
    $fieldset = $(evt.target).parents('fieldset')
    target_fieldset = $fieldset.attr('data-copy-to')
    target_value = $fieldset.find('input[type="radio"]:checked')
                            .val()

    # Sync language option between two separate fields
    $("[data-setting='#{target_fieldset}']").find("[type='radio']")
        .attr("checked",false).checkboxradio("refresh")

    $("[data-setting='#{target_fieldset}']").find("[value='#{target_value}']")
        .attr("checked",true).checkboxradio("refresh")

    @saveOptions()
    return true

  revealSubquestion: (evt) ->
    sub_q = 'data-reveal-subquestion'
    subs = $("[#{sub_q}]").attr(sub_q)
    $("##{subs}").slideUp()

    sub = $(evt.target).attr(sub_q)
    if sub?
      sub = $("##{sub}")
      sub.slideDown()
      first = sub.find(".ui-radio:first")
      first.find('input').attr('checked', true).checkboxradio("refresh")

    return true
  
  saveOptions: (evt) ->
    if app.debug == true
      console.log evt
    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false
       
    _data = @$el.find('select[name="data-storage"]')
    _audio = @$el.find('select[name="play-audio"]')

    enable_cache = toBool _data.slider().val()
    enable_audio = toBool _audio.slider().val()

    interface_language = $("[data-setting='interface_language']")
                            .find('input[type="radio"]:checked').val()

    help_language = $("[data-setting='help_language']")
                            .find('input[type="radio"]:checked').val()

    new_settings = {
      enable_cache:       enable_cache
      enable_audio:       enable_audio
      interface_language: interface_language
      help_language:      help_language
    }

    app.options.setSettings(new_settings, {
      store: true
    })
      

  template: OptionsTemplate

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

    _ui.attr("checked", true)
    _hl.attr("checked", true)

    # TODO: sync offline, or in localstorage

  render: ->
    if app.options.getSetting('interface_language') == 'sma'
      hide_sub = false
    else
      hide_sub = true

    @$el.html @template
      hide_sub: hide_sub

    @reloadSettings()

    # TODO: events for some reason aren't reregistered when returning to this
    # view.
    console.log "render"

