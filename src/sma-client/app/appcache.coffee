AppCacheStatus = require 'views/templates/app_cache_status'

module.exports = AppCacheHandler = () ->
  console.log "Initializing appCache"
  # TODO: need some sort of sync feedback for users
  #
  # Some log handlers for the console
  loadingFloat = () ->
    if $('#loading_float').length == 0
      loading = AppCacheStatus {
      	obj_count: 55
      }
      $('body').append loading
      loading = $('#loading_float')
    else
      loading = $('#loading_float')
    loading.fadeOut(4500)
    return loading

  updateLoadingCount = (count, total) =>
    loader = loadingFloat()
    loader.fadeIn(500)
    _count = loader.find('#cache_count')
    _total = loader.find('#cache_total')
    _count.html(count)
    _total.html(total)
    return true

  incrementLoadingCount = () =>
    loader = loadingFloat()
    _count = loader.find('#cache_count')
    _total = loader.find('#cache_total')

    count = parseInt loader.find('#cache_count').html()
    total = parseInt loader.find('#cache_total').html()

    if isNaN(count) or isNaN(total)
      count = 0
      total = 0

    updateLoadingCount(count + 1, total)

  updateLoadingStatusMessage = (msg) =>
    loader = loadingFloat()
    loader.fadeIn(500)
    _msg = loader.find('#status #message')
    _msg.html(msg)
    return true

  fadeOutLoader = () ->
    loader = loadingFloat().fadeOut(1500)
    return true

  window.updateLoadingCount = updateLoadingCount
  window.incrementLoadingCount = incrementLoadingCount
  window.updateLoadingStatusMessage = updateLoadingStatusMessage
  window.fadeOutLoader = fadeOutLoader

  loadingFloat()

  if window.applicationCache
    window.applicationCache.onchecking = (e) ->
      console.log "onchecking"
      updateLoadingStatusMessage("Checking for new media files.")

    window.applicationCache.onnoupdate = (e) ->
      console.log("No updates")
      updateLoadingStatusMessage("No updates.")
      fadeOutLoader()

    window.applicationCache.onupdateready = (e) ->
      console.log("Update ready")
      updateLoadingStatusMessage("Update finished.")
      fadeOutLoader()

    window.applicationCache.onobsolete = (e) ->
      console.log("Obsolete")

    window.applicationCache.ondownloading = (e) ->
      console.log("Downloading")
      updateLoadingStatusMessage("Downloading ...")

    window.applicationCache.oncached = (e) ->
      console.log("Cached")
      updateLoadingStatusMessage("Offline files downloaded.")
      fadeOutLoader()

    window.applicationCache.onerror = (e) ->
      console.log("Error")
      updateLoadingStatusMessage("Caching error! Error connecting.")

    counter = 0
    window.applicationCache.onprogress = (e) ->
      console.log("checking")
      console.log("Progress: downloaded file " + counter)
      incrementLoadingCount()
      counter++

    window.addEventListener "online", (e) ->
      # TODO: things to do here
      console.log "you are online"
      window.OnlineStatus = true

    window.addEventListener "offline", (e) ->
      # TODO: things to do here
      console.log "you are offline"
      window.OnlineStatus = false
  else
    fadeOutLoader()
