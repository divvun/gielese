module.exports = class GlobalOptionsView extends Backbone.View

  className: 'hello'
  # TODO: events for adjusting options
  # TODO: appCache option, remove event bindings, and manifest from <body />
  #       element
  #       ? Multiple different manifests depending on what user wants to store?

  template: require './templates/global_options'

  render: ->
    @$el.html @template
    this

