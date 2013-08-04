
module.exports = class CategoryMenu extends Backbone.View

  events:
    "click #login_button": 'displayLogin'
    "click #userinfo_button": 'displayUserInfo'
  
  className: 'hello'
  id: "hello"

  displayUserInfo: (e) ->
    # TODO: catually impliment user info stuff, for now just log out 
    console.log app.user
    return false

  displayLogin: (evt) ->
    # TODO: where did username go? 
    if app.user
      window.location.hash = 'stats'
      return true
    app.auth.render_authentication_popup @$el, {
      success: (data, textStatus, jqXHR) =>
        un = data.user.username
        @$el.find('#login_button').find('.action').html " "
        @$el.find('#login_button').find('.user').html un
        @$el.find('#login_button').attr('href', "#stats")
        setTimeout(() =>
          app.auth.hide_authentication_popup @$el
          console.log "bbq"
        , 250)
    }

  template: require './templates/category_menu'

  render: ->
    @$el.html @template
    this
