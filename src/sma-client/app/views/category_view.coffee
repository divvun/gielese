
module.exports = class CategoryMenu extends Backbone.View

  events:
    "click #login_button": 'displayLogin'
    "click #userinfo_button": 'displayUserInfo'
  
  className: 'hello'
  id: "hello"

  displayLogin: (evt) ->
    # TODO: where did username go?
    if app.user
      window.location.hash = 'stats'
      return true
    app.auth.render_authentication_popup @$el, {
      success: () =>
        un = app.user.username
        @$el.find('#login_button').find('.action').html " "
        @$el.find('#login_button').find('.user').html un
        @$el.find('#login_button').attr('href', "#stats")
        setTimeout(() =>
          app.auth.hide_authentication_popup @$el
        , 250)
    }

  template: require './templates/category_menu'

  render: ->
    categories = app.categories.where
      main_menu: true

    labels = 'cba'
    _labels = labels.split('')
    withLabel = (c) =>
      if _labels.length == 0
        _labels = labels.split('')
      lab = _labels.pop(0)
      return [c, lab]

    chunks = window.arrayChunk(
      withLabel c for c in categories,
      3
    )
    @$el.html @template
      categories: chunks

    this
