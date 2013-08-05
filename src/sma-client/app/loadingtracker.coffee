module.exports = class LoadingTracker
  isReady: () ->
    for name, status of @dependencies
      if not status
      	return false
    console.log "In readiness."
    return true

  checkDeps: () ->
    if @isReady()
      @hideLoading()

  markReady: (name) ->
    @dependencies[name] = true
    @checkDeps()

  hideLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('hide')
      clearInterval(interval)
    ,1)
    return false

  showLoading: () ->
    interval = setInterval(() ->
      $.mobile.loading('show', {
        text: 'Loading...',
        textVisible: true,
        theme: 'a',
        html: ""
      })
      clearInterval(interval)
    ,1)
    return false

  constructor: (deps) ->
    @dependencies = deps
