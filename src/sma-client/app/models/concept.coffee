
module.exports = class Concept extends Backbone.Model
  # Compatibility with old version of bootstrap
  hasImage: () ->
    has_media = @.get('media')
    if 'image' of has_media
      if has_media.image.length > 0
        has_audio_file = _.shuffle(has_media.image)[0].path
        return has_audio_file
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
    if app.options.enable_audio and has_media.audio?
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
    concept_renderers =
      'img': (c) ->
        return "<img class='concept img_concept' src='#{c.get('concept_value')}' />"
      'text': (c) ->
        linebreaks = ///[-–—]///
        val = c.get('concept_value').split(linebreaks).join('-<br />')
        return "<span class='concept word_concept'>#{val}</span>"
    type = @.get('concept_type')
    return concept_renderers[type](@)

