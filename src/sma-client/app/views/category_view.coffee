
module.exports = class CategoryMenu extends Backbone.View

  events:
    "click #login_button": 'displayLogin'
  
  className: 'hello'
  id: "hello"

  displayLogin: ->
    console.log "popup trigger"

    formSubmit = (e) ->
      console.log "submitted"
      return false

    if $('#loginPopup').length == 0
      LoginTemplate = require './templates/login_modal'
      login_template = LoginTemplate()
      @$el.append(login_template)
      
      # Rerender elements
      $('#loginPopup input').textinput()
      $('#loginPopup button').button()
      
      # Events
      $('#loginPopup form').submit formSubmit

    # Show it
    popup = @$el.find("#loginPopup")
    popup.popup().show().popup('open')

    return false

  template: require './templates/category_menu'

  render: ->
    @$el.html @template
    this
