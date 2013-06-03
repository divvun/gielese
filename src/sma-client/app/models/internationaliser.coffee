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

  getLocale: (locale) ->
    @where({locale: locale})[0]


  getMessage: (locale, msg) ->
    loc = @getLocale(locale)
    if loc
      loc.getMessage(msg)
    return msg

  fakeGetText: (str) ->
    return @getMessage(window.app.options.help_lang, str)



