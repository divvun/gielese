class Internationalisation extends Backbone.Model
  getMessage: (str) ->
    msgs = @get('messages')
    localized = msgs[str]
    if localized?
      if localized
      	return localized
    return str

module.exports = class Internationalisations extends Backbone.Collection
  model: Internationalisation
  url: "/data/translations.json"

  fetch: () ->
    super
    app.loadingTracker.markReady('translations.json')
    @ready = true

    # console.log fGT("Help language")
  
  # where: (params) ->
  #   # TODO: features
  #   if 'semantics' of params
  #     new_coll = @whereSemantics(params.semantics)
  #     delete params.semantics
  #     if Object.keys(params).length > 0
  #       return new_coll.where(params)
  #     else
  #     	return new_coll.models
  #     
  #   super
    
  getLocale: (locale) ->
    @where({locale: locale})[0]


  getMessage: (locale, msg) ->
    loc = @getLocale(locale)
    if loc
      loc.getMessage(msg)
    return msg

  fakeGetText: (str) ->
    return @getMessage(window.app.options.help_lang, str)



