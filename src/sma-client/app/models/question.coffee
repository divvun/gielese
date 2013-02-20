module.exports = class Question extends Backbone.Model
  find_concepts: (conceptdb) ->
    
    max_answers = 4

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

    # Select a question concept
    if q_concepts.length > 0
      question = _.shuffle(q_concepts)[0]
      # TODO: what if there are no alternates, select other
      # less-matching concepts?

      # Alternate question concepts that match the question criteria
      alternates = _.shuffle(q_concepts).slice(1)
    else
      # TODO: better obvious error
      console.log "No concepts found for question."
      console.log _filters
      return [false, false, false]

    # Here are the direct translations of our question prompt
    # TODO: if word has no translations, things break here.
    # TODO: also if there are multiple translations in a language, we'll only
    #       get the first in the DB
    actual_answer_concepts = conceptdb.getTranslationsOf question
    actual_answer_concepts = actual_answer_concepts.filter (o) =>
                               o.get('language') == _to


    # Get translations of the alternate question concepts; these should have a
    # semantic match and thus be a little more difficult.
    alternate_translations = _.flatten(
      conceptdb.getTranslationsOf alt for alt in alternates
    )
    alternate_translations = alternate_translations.filter (o) =>
                               o.get('language') == _to
    
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

    answer_possibilities = answer_possibilities.slice(0, max_answers - 1)

    all_answer_possibilities = [actual_answer]
    all_answer_possibilities = all_answer_possibilities.concat answer_possibilities
    all_answer_possibilities = _.uniq(all_answer_possibilities)

    # Fill the array with missing answers if we have too few.
    if all_answer_possibilities.length < max_answers
      difference = max_answers - all_answer_possibilities.length
      for c in _.range(0, difference)
        for a in _.shuffle(potential_incorrect_answers)
          if (a != actual_answer) and !(a in all_answer_possibilities)
            all_answer_possibilities.push a
            break

    return [ question
           , all_answer_possibilities
           , actual_answer
           ]

