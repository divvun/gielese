LeksaConceptTemplate = require '../views/templates/leksa_concept'
SoundLoadingTemplate = require '../views/templates/sound_loading'

module.exports = class Concept extends Backbone.Model
  # Compatibility with old version of bootstrap
  idAttribute: "c_id"

  defaults:
    fails: false

  successRateInUserLog: () ->
    log_entries_for_concept = app.userprogression.where
      question_concept_value: @get('concept_value')
    correct_values = app.userprogression.where
      question_concept_value: @get('concept_value')
      question_correct: true

    total = log_entries_for_concept.length
    count_correct = correct_values.length
    if total > 0
      return count_correct/total
    else
      return false

  hasThumbnail: () ->
    thumbs = false
    has_media = @.get('media')
    if 'image' of has_media
      if has_media.image.length > 0
        thumbs = _.filter has_media.image, (i) ->
          return i.size == 'thumbnail'
        if thumbs.length == 0
          thumbs = false
    return thumbs

  hasImage: (opts = {}) ->
    if not opts.device
      device = app.device_type
    else
      device = opts.device

    if not opts.size
      size = app.media_size
    else
      size = opts.size

    console.log [device, size]
    # TODO: maybe preference to image size over device? i.e., if large/tablet
    # doesn't exist, but large/mobile does, take that one
    has_media = @.get('media')
    if 'image' of has_media
      if has_media.image.length > 0

        images_for_device = _.filter has_media.image, (i) ->
          return i.size == size and i.device == device

        if images_for_device.length == 0
          return has_media.image[0].path

        if images_for_device.length > 0
          return images_for_device[0].path

        return images_for_device
    return "/static/images/missing_concept_image.jpg"

  getTranslationsToLang: (lang) ->
    @getTranslations().filter (c) =>
      c.get('language') == lang

  getTranslations: () ->
    @collection.filter (comp_concept) =>
      if _.contains( @.get('translations')
                   , comp_concept.get('c_id')
                   )
        return true
      else
        return false

  hasAudio: () ->
    has_media = @.get('media')
    if app.options.getSetting('enable_audio') and has_media.audio?
      if has_media.audio.length > 0
        has_audio_file = _.shuffle(has_media.audio)[0].path
        return has_audio_file
    return false
  
  playAudio: (opts={}) ->
    # TODO: user feedback about whether audio is downloaded or not.

    loading = $(document).find('#sound_loading_bar')
    if loading.length == 0
      $('body').append SoundLoadingTemplate
      loading = $('body').find('#sound_loading_bar')
    
    console.log loading

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
      console.log this.duration
      # show audio loading indicator
      console.log "whileloading..."
      console.log "#{this.bytesLoaded} / #{this.bytesTotal}"
      if this.bytesTotal >= this.bytesLoaded
        if loading.css('display') == 'none'
          loading.fadeIn()
      if this.bytesTotal == this.bytesLoaded
        loading.fadeOut()

    has_audio_file = @hasAudio()
    if has_audio_file and soundManager.enabled
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
            url: has_audio_file
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

        if sound_obj.url == has_audio_file
          console.log "repeat"
        else
          console.log "no repeat"
          sound_obj.url = has_audio_file
          window.so = sound_obj
          console.log sound_obj.onfinished

        sound_obj.play({position:0})
      else
        if app.debug
          console.log "creating sound with flash"
        soundManager.destroySound(sound_id)
        s = soundManager.createSound({
          id: sound_id
          url: has_audio_file
          onfinish: finished_event
          onerror: error_event
          onplay: begin_event
          whileloading: whileload_event
        })
        s.play()
      return s

    # here's what to do if there was no sound or sound manager failed somehow
    if opts.finished
      opts.finished()
    else
      return false

  render_concept: () ->
    LeksaConceptTemplate({
      concept: @
      concept_type: @.get('concept_type')
      concept_value: @.get('concept_value')
    })
