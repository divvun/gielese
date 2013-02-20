module.exports = class GlobalOptionsView extends Backbone.View

  className: 'hello'

  template: require './templates/global_options'

  render: ->
    @$el.html @template
    this

