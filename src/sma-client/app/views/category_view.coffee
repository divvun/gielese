
module.exports = class CategoryMenu extends Backbone.View

  events:
    "click #login_button": 'displayLogin'
  
  className: 'hello'
  id: "hello"

  displayLogin: ->
    app.auth.render_authentication_popup @$el

  template: require './templates/category_menu'

  render: ->
    @$el.html @template
    this
