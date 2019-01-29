SplashTemplate = require './templates/splash'

module.exports = class SplashPage extends Backbone.View

  hideLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('hide')
      clearInterval(interval)
    ,1)
    return false

  showLoading: (txt) ->
    interval = setInterval(() =>
      $.mobile.loading('show', {
        text: txt,
        textVisible: true,
        theme: 'a',
        html: ""
      })
      clearInterval(interval)
    ,1)
    return false

  id: "loading_splash"

  template: SplashTemplate

  render: ->
    @$el.html @template
    this


