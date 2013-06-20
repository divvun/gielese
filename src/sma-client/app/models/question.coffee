# TODO: questions still being displayed not enough times, check what's going on
# in filtering

filterByLang = (lang, concepts) ->
  concepts.filter (o) => o.get('language') == lang

class QuestionInstance
  constructor: (@generator, @question, @choices, @answer, @current_count,
                @question_total, @total_correct) ->
    console.log "created instance"
    @choices = _.shuffle(@choices)

orderConceptsByProgression = (q, concepts, up) ->
  # For now want to organize out those that have been shown the most, so, 
  # sort by count of concepts in userprogression that are correct
  debug = window.app.debug

  # Grab only the user progression for this question
  userprogression = up.filter (u) =>
    u.get('question').cid == q.cid

  if debug
    console.log "#{q.cid} - #{userprogression.length} run-throughs"

  if userprogression.length == 0
  	return concepts
  
  getProgressionCorrectCountForConcept = (c) =>
    userprogression
      .filter (up) =>
        up.get('question') == q
      .filter (up) =>
        up.get('question_concept') == c.get('c_id')
      .filter (up) =>
        up.get('question_correct')
      .length

  # take out of cycle once they've been shown 3 times
  countLessThanFour = (c) =>
    getProgressionCorrectCountForConcept(c) < 4
  
  last_concept = up.last()

  if up.models.length > 0
    excluding_last_concept = _.filter(concepts, (c) -> c.get('question_concept_value') != last_concept.id)
    if excluding_last_concept.length == 0
      excluding_last_concept = concepts
  else
    excluding_last_concept = concepts

  ordered_by_frequency = _.sortBy( _.filter(excluding_last_concept, countLessThanFour)
                                 , getProgressionCorrectCountForConcept
                                 )

  if debug
    f_strings = ordered_by_frequency.map (f) ->
        "#{getProgressionCorrectCountForConcept(f)} - #{f.get('concept_value')}"

    if f_strings.length > 0
      console.log f_strings.join('\n')

  if ordered_by_frequency.length == 0
  	if debug
  	  console.log "No more concepts fittting progression"
  	return concepts

  return ordered_by_frequency

module.exports = class Question extends Backbone.Model

  user_completed_question: () ->
    userprogression = app.leksaUserProgression
    correct_count = 3
    # Determine whether the user has completed the question, by answering all
    # concepts in level correctly at least once (TODO: maybe not enough?)

    if userprogression.length > 0
      logs_for_question = userprogression
          .filter (up) =>
            up.get('question').cid == @cid
          .filter (up) ->
            up.get('question_correct') == true
      concepts_for_question = logs_for_question
          .map (up) ->
            up.get('question_concept')
    else
      return false

    getProgressionCorrectCountForConcept = (c) =>
      userprogression
        .filter (up) =>
          up.get('question_concept') == c.get('c_id')
        .filter (up) =>
          up.get('question_correct')
        .filter (up) =>
          up.get('question').cid == @cid
        .length
    
    concepts = @select_question_concepts window.app.conceptdb
    
    counts = []
    for c in concepts
      corrects = getProgressionCorrectCountForConcept(c)
      if corrects > 3
      	corrects = 3
      counts.push corrects

    if _.uniq(counts).length == 1
      if _.max(counts) == 3 and _.uniq(counts)[0] == 3
      	return true
    # For each concept, need to check that user has gotten it right three
    # times.

    return false

  select_question_concepts_by_progression: (conceptdb, up) ->
    return orderConceptsByProgression(
      @,
      @select_question_concepts(conceptdb),
      up
    )

  select_question_concepts: (conceptdb) ->
    default_similarity = {
      'features': false
      'semantics': false
    }

    _filters = @get('filters')
    _answer_sim = @get('answer_similarity') || default_similarity

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
    return q_concepts

  find_concepts: (conceptdb, userprogression) ->

    # TODO: include userprogression
    #
    if @.get('answers')
      max_answers = @.get('answers')
    else
      max_answers = 4

    answer_possibilities = []

    default_similarity = {
      'features': false
      'semantics': false
    }

    _filters = @get('filters')
    _answer_sim = @get('answer_similarity') || default_similarity

    _from = _filters.from_language
    _to   = _filters.to_language

    q_concepts = @select_question_concepts_by_progression(
      @select_question_concepts(conceptdb),
      userprogression
    )
    # Concepts left (probably need to multiple by display count)
    total_correct_answers_for_question = userprogression.where({
    	game_name: "leksa",
    	question_correct: true,
    	question: @,
    }).length

    concepts_total = @select_question_concepts(conceptdb).length
    concepts_left = concepts_total - q_concepts.length

    # Select a question concept
    if q_concepts.length > 0
      question = _.shuffle(q_concepts)[0]
      # Alternate question concepts that match the question criteria
      alternates = _.shuffle(q_concepts).slice(1)
    else
      # TODO: better obvious error
      # TODO: mark question as producing a fail so it is removed from
      # cycle
      console.log "No concepts found for question."
      console.log _filters
      return false

    # Here are the direct translations of our question prompt
    # TODO: if word has no translations, things break here.
    # TODO: also if there are multiple translations in a language, we'll only
    #       get the first in the DB
    actual_answer_concepts = filterByLang(_to, conceptdb.getTranslationsOf question)

    if actual_answer_concepts.length == 0
      console.log " * No translations to #{_to} for #{question.get('concept_value')}"
      inst = false
      @.set('fails', true)

    # Get translations of the alternate question concepts; these should have a
    # semantic match and thus be a little more difficult.
    alternate_translations = filterByLang _to, _.flatten(
      conceptdb.getTranslationsOf alt for alt in alternates
    )
    
    answer_possibilities = alternate_translations

    actual_answer = _.shuffle(actual_answer_concepts)[0]
    
    # Make some potential incorrect answers to fill things in.

    # TODO: feature intersection
    # here we get answers that are similar as described in the answer similarity
    potential_incorrect_answers = conceptdb.filter (concept) =>
      target_language = concept.get('language') == _to
      # TODO: feature match?
      if _answer_sim.semantics
        semantics  = _.intersection( concept.get('semantics')
                                   , _answer_sim.semantics
                                   )
        if target_language and concept != actual_answer and semantics.length > 0
          return true
        else
          return false
      else
        if target_language and concept != actual_answer
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

    if question and all_answer_possibilities.length > 0 and actual_answer
      inst = new QuestionInstance( @
                                 , question
                                 , all_answer_possibilities
                                 , actual_answer
                                 , concepts_left
                                 , concepts_total
                                 , total_correct_answers_for_question
                                 )

    else
      console.log " * Couldn't generate a question instance for #{@.get('name')}"
      console.log "   removing question from cycle."
      inst = false
      @.set('fails', true)

    return inst

