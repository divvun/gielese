LeksaConceptTemplate = require '../views/templates/leksa_concept'

module.exports = class Concept extends Backbone.Model
  # Compatibility with old version of bootstrap
  idAttribute: "c_id"

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
      size = "small"
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
    return false

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
    has_audio_file = @hasAudio()
    if has_audio_file and soundManager.enabled
      if opts.sound_id?
        sound_id = opts.sound_id
      else
        sound_id = "concept-audio-#{@.get('c_id')}"
      soundManager.destroySound(sound_id)
      s = soundManager.createSound({
        id: sound_id
        url: has_audio_file
      })
      if s.isHTML5
        s._a.playbackRate = opts.rate
      s.play()
      return s

    return false

  render_concept: () ->
    LeksaConceptTemplate({
      concept: @
      concept_type: @.get('concept_type')
      concept_value: @.get('concept_value')
    })
