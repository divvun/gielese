
module.exports = class Concept extends Backbone.Model
    #
  # attributes: { language: false # string (3char)
  #             , concept_type: false # string (3char)
  #             , concept_value: # string (word, url)
  #             , semantics: [ ] # list
  #             , features: [ ] # list
  #             , c_id: null # int
  #             , translations: [ ] # list of related ints
  #             }
  hasImage: () ->
    has_media = @.get('media')
    if 'image' of has_media
      if has_media.image.length > 0
        has_audio_file = has_media.image[0].path
        return has_audio_file
    return false

  hasAudio: () ->
    has_media = @.get('media')
    if app.options.enable_audio and ('audio' of has_media)
      if has_media.audio.length > 0
        has_audio_file = has_media.audio[0].path
        return has_audio_file
    return false
  
  playAudio: (sound_id) ->
    has_media = @.get('media')
    if app.options.enable_audio and ('audio' of has_media)
      if has_media.audio.length > 0
        has_audio_file = has_media.audio[0].path
        if has_audio_file and soundManager.enabled
          if not sound_id?
            sound_id = "concept-audio-#{@.cid}"
          soundManager.destroySound(sound_id)
          soundManager.createSound({
             id: sound_id
             url: "/static#{has_audio_file}"
          })
          soundManager.play(sound_id)

    return false

  render_concept: () ->
    concept_renderers =
      'img': (c) ->
        return "<img class='concept img_concept' src='#{c.get('concept_value')}' />"
      'text': (c) ->
        return "<span class='concept word_concept'>#{c.get('concept_value')}</span>"
    type = @.get('concept_type')
    return concept_renderers[type](@)


