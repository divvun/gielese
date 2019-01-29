NoMoreProgression = require '/models/exceptions/progression_cycle_done'

module.exports = orderConceptsByList = (q, concepts, ordering) ->

  if q.attributes.type == 'image_to_word'
    get_canonical_concept_value = (c) =>
      if c? and c
        answer_lang = q.attributes.filters.to_language
        txls = _.first c.getTranslationsToLang(answer_lang)
        return txls.get('concept_value')
      else
        return false
  else
    chop_concept = (a) -> a
    get_canonical_concept_value = (c) -> c.get('concept_value')

  if app.debug
    console.log "#{q.cid} - #{user_prog_for_question.length} run-throughs"

  if ordering.length == 0
    return concepts

  last_concept = app.userprogression.last()
  if app.debug
    console.log "Last concept: "
    console.log last_concept

  concepts_by_ordering = []
  for c in ordering
    _conc = _.first(concepts.filter((v) => get_canonical_concept_value(v) == c))
    if _conc
      concepts_by_ordering.push(_conc)

  if app.debug
    f_strings = ordered_by_frequency.map (f) ->
      "#{progressionCorrectCountForConcept(f)} - #{f.get('concept_value')}"

    if f_strings.length > 0
      console.log f_strings.join('\n')

  if concepts_by_ordering.length == 0
    if app.debug
      console.log "No more concepts fitting progression"
    err = new NoMoreProgression()
    throw err

  concepts_by_ordering

