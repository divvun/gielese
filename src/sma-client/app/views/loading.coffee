module.exports = class LoadingView extends Backbone.View

  className: 'loading'
  id: "loading"

  template: require './templates/loading'

  render: ->
    @$el.html @template
    app.loadingTracker.showLoading()
    i = 0
    console.log "int #{i}"
    @$el.find("pre").html("""
        Concepts:  #{app.conceptdb.models.length}
        Questions: #{app.questiondb.models.length}
    """)
    # app.router.index()
    this

