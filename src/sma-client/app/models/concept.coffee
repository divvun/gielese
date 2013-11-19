LeksaConceptTemplate = require '../views/templates/leksa_concept'

module.exports = class Concept extends Backbone.Model
  # Compatibility with old version of bootstrap
  idAttribute: "c_id"

  defaults:
    fails: false

  successRateInUserLog: () ->
    log_entries_for_concept = app.leksaUserProgression.where
      question_concept_value: @get('concept_value')
    correct_values = app.leksaUserProgression.where
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
    
    if opts.finished
      finished_event = opts.finished
    else
      finished_event = () -> return false

    has_audio_file = @hasAudio()
    if has_audio_file and soundManager.enabled
      sound_id = "concept_audio"

      # Have to have different behavior for html5-only, because of iOS
      # limitations
      if soundManager.html5Only
        sound_obj = soundManager.getSoundById(sound_id)
        # grab sound obj if it hasn't been created yet
        if not sound_obj
          sound_obj = soundManager.createSound
            id: sound_id
            url: has_audio_file
            onfinish: finished_event
          sound_obj._a.playbackRate = opts.rate
        if sound_obj.url == has_audio_file
          console.log "repeat"
        else
          console.log "no repeat"
          sound_obj.url = has_audio_file

        sound_obj.play({position:0})
      else
        soundManager.destroySound(sound_id)
        s = soundManager.createSound({
          id: sound_id
          url: has_audio_file
          onfinish: finished_event
        })
        s.play()
      return s

    return false

  render_concept: () ->
    LeksaConceptTemplate({
      concept: @
      concept_type: @.get('concept_type')
      concept_value: @.get('concept_value')
    })
