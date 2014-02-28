SoundLoadingTemplate = require '../views/templates/sound_loading'

module.exports = class AudioPlayer

  playAndroid: (path) ->
    # TODO: may need to update path to be relative to whatever storage
    window.media_obj = new Media('file:///android_asset/www/' + path)
    window.media_obj.play()
    return true

  playPath: (path, opts={}) ->
    # TODO: user feedback about whether audio is downloaded or not.
    if window.PhoneGapIndex
      if window.device.platform == "Android"
        @playAndroid(path)
        return true

    loading = $(document).find('#sound_loading_bar')
    if loading.length == 0
      $('body').append SoundLoadingTemplate
      loading = $('body').find('#sound_loading_bar')
    
    error_event = () =>
      console.log "Audio playing error"
      return false

    finished_event = () =>
      loading.fadeOut()
      opts.finished() if opts.finished?
      return false

    begin_event = () =>
      loading.fadeOut()
      opts.begin() if opts.begin?
      return false

    whileload_event = () ->
      if this.bytesTotal >= this.bytesLoaded
        if loading.css('display') == 'none'
          loading.fadeIn()
      if this.bytesTotal == this.bytesLoaded
        loading.fadeOut()

    if soundManager.enabled
      sound_id = "concept_audio"

      # Have to have different behavior for html5-only, because of iOS
      # limitations
      if soundManager.html5Only
        if app.debug
          console.log "html5 only"
        sound_obj = soundManager.getSoundById(sound_id)
        # grab sound obj if it hasn't been created yet
        if not sound_obj
          if app.debug
            console.log "creating sound obj"
          sound_obj = soundManager.createSound
            id: sound_id
            url: path
            onfinish: finished_event
            onerror: error_event
            onplay: begin_event
            whileloading: whileload_event
          sound_obj._a.playbackRate = opts.rate
        else
          if app.debug
            console.log "sound obj exists"
          # update the onfinished event
          sound_obj.options.onfinish = finished_event
          sound_obj.options.onerror = error_event
          sound_obj.options.onplay = begin_event
          sound_obj.options.whileloading = whileload_event

        if sound_obj.url == path
          if app.debug
            console.log "concept.playAudio: repeat"
        else
          if app.debug
            console.log "concept.playAudio: no repeat"
          sound_obj.url = path
          window.so = sound_obj

        sound_obj.play({position:0})
      else
        if app.debug
          console.log "creating sound with flash"
        soundManager.destroySound(sound_id)
        s = soundManager.createSound
          id: sound_id
          url: path
          onfinish: finished_event
          onerror: error_event
          onplay: begin_event
          whileloading: whileload_event

        s.play({position:0})
      return s

    # here's what to do if there was no sound or sound manager failed somehow
    if opts.finished
      opts.finished()
    else
      return false
  
