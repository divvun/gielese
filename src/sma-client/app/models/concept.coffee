LeksaConceptTemplate = require '../views/templates/leksa_concept'
SoundLoadingTemplate = require '../views/templates/sound_loading'

module.exports = class Concept extends Backbone.Model
  # Compatibility with old version of bootstrap
  idAttribute: "c_id"

  defaults:
    fails: false
    last_sound_path: ''

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

  hasVideo: (opts = {}) ->
    if not opts.device
      device = app.device_type
    else
      device = opts.device

    if not opts.size
      size = app.media_size
    else
      size = opts.size

    if not opts.format
      format = app.video_format
    else
      format = opts.format

    # TODO: maybe preference to image size over device? i.e., if large/tablet
    # doesn't exist, but large/mobile does, take that one

    has_media = @.get('media')

    path_infix = ''
    if not window.PhoneGapIndex
      path_infix = '/'

    if 'videos' of has_media
      if has_media.videos.length > 0

        videos_for_device = _.filter has_media.videos, (i) ->
          return i.size == size and i.device == device and i.format == format

        if videos_for_device.length == 0
          return false

        if videos_for_device.length > 0
          return path_infix + videos_for_device[0].path

        return videos_for_device

    if opts.no_default
      return false

    return path_infix + "static/images/missing_concept_image.jpg"

  hasImage: (opts = {}) ->
    if not opts.device
      device = app.device_type
    else
      device = opts.device

    if not opts.size
      size = app.media_size
    else
      size = opts.size

    if not opts.gif
      gif = false
    else
      gif = true

    # TODO: maybe preference to image size over device? i.e., if large/tablet
    # doesn't exist, but large/mobile does, take that one
    has_media = @.get('media')

    path_infix = ''
    if not window.PhoneGapIndex
      path_infix = '/'

    if 'image' of has_media
      if has_media.image.length > 0

        images_for_device = _.filter has_media.image, (i) ->
          return i.size == size and i.device == device

        if gif
          gifs = _.filter images_for_device, (i) ->
            return i.path.search('.gif') > -1
          if gifs.length > 0
            return path_infix + gifs[0].path
        else
          images_for_device = _.filter images_for_device, (i) ->
            return i.path.search('.gif') == -1

        if images_for_device.length == 0
          return path_infix + has_media.image[0].path

        if images_for_device.length > 0
          return path_infix + images_for_device[0].path

        return images_for_device

    if opts.no_default
      return false

    return path_infix + "static/images/missing_concept_image.jpg"

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
    # Find an audio path in the media, however track the previous one that was
    # selected, and do not repeat if possible. Otherwise if there is only one
    # audio track, that will just play always.
    #

    has_media = @.get('media')
    is_not_last_path = (s) => s.path != @last_sound_path

    path_infix = ''
    if not window.PhoneGapIndex
      path_infix = '/'

    if app.options.getSetting('enable_audio') and has_media.audio?
      if has_media.audio.length > 0

        audios = has_media.audio

        if audios.length > 1
          audios = _.filter(has_media.audio, is_not_last_path)

        has_audio_file = _.first(_.shuffle(audios)).path

        if audios.length > 1
          @last_sound_path = has_audio_file

        return path_infix + has_audio_file

    return false
  
  playAudio: (opts={}) ->
    # TODO: user feedback about whether audio is downloaded or not.
    has_audio_file = @hasAudio()
    if has_audio_file
      app.audio.playPath(has_audio_file, opts)

  render_concept: () ->
    concept_media_value = @.get('concept_value')
    c_type = @.get('concept_type')

    if @.get('concept_type') == 'img'
      concept_media_value = @hasImage()
    if @.get('concept_type') == 'vid'
      concept_media_value = @hasVideo()
      c_type = 'img'
    
    LeksaConceptTemplate({
      concept: @
      concept_type: c_type
      concept_value: concept_media_value
    })
