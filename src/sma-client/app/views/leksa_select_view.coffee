module.exports = class HelloView extends Backbone.View

  className: 'leksa_select'
  id: "leksa_select"

  template: require './templates/leksa_select'

  render: ->
    @$el.html @template
    this

