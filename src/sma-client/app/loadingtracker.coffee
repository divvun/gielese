class LoadingDepsFailed extends Error
  constructor: (@params...) ->
    super

module.exports = class LoadingTracker
  isReady: () ->
    for name, status of @dependencies
      if not status
        return false
    console.log "In readiness."
    return true

  waitForDeps: (opts = {}) ->
    # TODO: minimum duration to keep trying for, and then redirect if nothing
    # works
    if @isReady()
      if opts.ready?
        return opts.ready()
      else
        return true
    else
      @showLoading()

    @check_handler = setInterval(
      () =>
        if @isReady()
          if opts.extra_test?
            if not opts.extra_test()
              return false

          clearInterval(@check_handler)
          @hideLoading()

          if opts.ready?
            return opts.ready()
          else
            return false

        if opts.timeout?
          if total_wait > opts.timeout
            clearInterval(@check_handler)
            @hideLoading()
            if opts.failed?
              return opts.failed()
            else
              throw new LoadingDepsFailed()
    , 500)
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
