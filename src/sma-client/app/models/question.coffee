module.exports = class Question extends Backbone.Model
  find_concepts: (conceptdb) ->

    question_possibilities = []
    answer_possibilities = []

    _filters = @get('filters')
    _answer_sim = @get('answer_similarity')

    _from = _filters.from_language
    _to   = _filters.to_language

    # Possible question prompts matching filters
    q_concepts = conceptdb.filter (concept) =>
      semantics  =  _.intersection( concept.get('semantics')
                                  , _filters.semantics
                                  )
      target_language = concept.get('language') == _from
      # TODO: feature match?
      if target_language and semantics.length > 0
        return true
      else
        return false

    # Select a question
    if q_concepts.length > 0
      question = _.shuffle(q_concepts)[0]
      # TODO: what if there are no alternates, select other
      # less-matching concepts?
      alternates = _.shuffle(q_concepts).slice(1)
    else
      # TODO: better obvious error
      console.log "No concepts found for question."
      console.log _filters

    # Question prompt
    console.log "question: #{question.get('concept_value')}"

    # Here are the direct translations of our question prompt
    # TODO: if word has no translations, things break here.
    actual_answer_concepts = conceptdb.getTranslationsOf question
    actual_answer_concepts = actual_answer_concepts.filter (o) =>
                               o.get('language') == _to

    console.log "answer: #{actual_answer_concepts[0].get('concept_value')}"

    # Alternative similar answers
    console.log "#{alternates.length} alternatives"

    alternate_translations = _.flatten(
      conceptdb.getTranslationsOf alt for alt in alternates
    )
    alternate_translations = alternate_translations.filter (o) =>
                               o.get('language') == _to
    
    for alt in alternate_translations
      console.log " - #{alt.get('concept_value')}"
    
    question_possibilities = q_concepts
    answer_possibilities = alternate_translations
    # TODO: multiple answers?
    actual_answer = actual_answer_concepts[0]
    
    # Make some potential incorrect answers to fill things in.

    # TODO: feature intersection
    # here we get answers that are similar as described in the answer similarity
    potential_incorrect_answers = conceptdb.filter (concept) =>
      semantics  = _.intersection( concept.get('semantics')
                                 , _answer_sim.semantics
                                 )
      target_language = concept.get('language') == _to
      # TODO: feature match?
      if target_language and semantics.length > 0 and concept != actual_answer
        return true
      else
        return false

    potential_incorrect_answers = _.shuffle(potential_incorrect_answers)

    leftovers = 4 - answer_possibilities.length
    console.log "fetch #{leftovers} leftovers"
    fillings = potential_incorrect_answers.slice(0, leftovers)
    console.log "fetched #{fillings.length} leftovers"


    answer_possibilities_with_fillings = []
    answer_possibilities_with_fillings = answer_possibilities_with_fillings.concat answer_possibilities
    answer_possibilities_with_fillings = answer_possibilities_with_fillings.concat fillings
    answer_possibilities_with_fillings.push   actual_answer
    answer_possibilities_with_fillings = _.uniq(answer_possibilities_with_fillings)

    return [ question
           , answer_possibilities_with_fillings
           , actual_answer
           ]

