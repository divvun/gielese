
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

  displayLogin: ->
    # TODO: where did username go? 
    app.auth.render_authentication_popup @$el, {
      success: (data, textStatus, jqXHR) =>
        un = data.user.username
        setTimeout(() =>
          app.auth.hide_authentication_popup @$el
          @$el.find('#login_button .action').html " "
          @$el.find('#login_button .user').html un
        , 250)
    }

  template: require './templates/category_menu'

  render: ->
    @$el.html @template
    this
