This module is somewhat complex, thus it is written in Literate Coffeescript.

This class is returned when a question is generated.

    class QuestionInstance
      constructor: (@generator, @question, @choices, @answer, @current_count,
                    @question_total, @total_correct) ->
        if window.app.debug
          console.log "created instance"
        @choices = _.shuffle(@choices)

## Question model

This is the only thing we need to export from this module.

    module.exports = class Question extends Backbone.Model

Determine whether the user has completed this question, here, defined as
answering all concepts in level correctly at least once.

      user_completed_question: () ->
        userprogression = app.leksaUserProgression
        correct_count = 2

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
              up.get('question_concept') == c.get('id')
            .filter (up) =>
              up.get('question_correct')
            .filter (up) =>
              up.get('question').cid == @cid
            .length
        
        concepts = @select_question_concepts window.app.conceptdb
        
        counts = []
        for c in concepts
          corrects = getProgressionCorrectCountForConcept(c)
          if corrects > correct_count
            corrects = correct_count
          counts.push corrects

        if _.uniq(counts).length == 1
          if _.max(counts) == correct_count and _.uniq(counts)[0] == correct_count
            return true

        # For each concept, need to check that user has gotten it right three
        # times.
        return false

      filter_concepts_by_media: (concepts, media_size) ->
        _ms = "/#{media_size}/"
        filtered_concepts = _.filter concepts, (c) =>
          if c.get('language') == 'img'
            return c.get('concept_value').search(_ms) > -1
          else
      	    return true

        if filtered_concepts.length == 0
          if window.app.debug
            console.log "* Unable to filter by media type because concepts do not"
            console.log "  have a media type that matches device. Falling back to"
            console.log "  whatever is available."
          return concepts

        return filtered_concepts

      select_question_concepts_by_progression: (conceptdb, userprog) ->
        orderConceptsByProgression = require './helpers/concept_progression_sorter'
        return orderConceptsByProgression(@,
          @filter_concepts_by_media(
            @select_question_concepts(conceptdb), 'small'
          ),
          userprog
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
        userlang = ISOs.two_to_three app.options.getSetting('help_language')

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

        if _to == "USERLANG"
          console.log "USERLANG found, replacing with user help lang"
          console.log userlang
          _to = userlang

        question_concepts = @select_question_concepts(conceptdb)
        q_concepts = @select_question_concepts_by_progression(
          question_concepts,
          userprogression
        )

        # Concepts left (probably need to multiple by display count)
        total_correct_answers_for_question = userprogression.where({
            game_name: "leksa",
            question_correct: true,
            question: @,
        }).length

        concepts_total = question_concepts.length
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
        actual_answer_concepts = question.getTranslationsToLang(_to)

        if actual_answer_concepts.length == 0
          console.log " * No translations to #{_to} for #{question.get('concept_value')}"
          inst = false
          @.set('fails', true)

        filterByLang = (lang, concepts) ->
          concepts.filter (o) => o.get('language') == lang

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

        if @attributes.type == 'word_to_image'
          chop_concept = (a) -> a.split('/').slice(-1)[0]
        else
          chop_concept = (a) -> a

        uniq_for_concept_value = (cs) =>
          _cs = []
          _cvs = []
          for c in cs
            _cv = chop_concept c.attributes.concept_value
            if _cv in _cvs
              continue
            _cs.push c
            _cvs.push _cv
          return _cs

        potential_incorrect_answers = _.shuffle(
          uniq_for_concept_value potential_incorrect_answers
        )

        answer_possibilities = answer_possibilities.slice(0, max_answers - 1)

        all_answer_poss = [actual_answer]
        all_answer_poss = all_answer_poss.concat answer_possibilities
        all_answer_poss = uniq_for_concept_value all_answer_poss

        # Fill the array with missing answers if we have too few.
        if all_answer_poss.length < max_answers
          difference = max_answers - all_answer_poss.length
          concept_values = (a.attributes.concept_value for a in all_answer_poss)
          for c in _.range(0, difference)
            for a in _.shuffle(potential_incorrect_answers)
              if (a != actual_answer) and !(a in all_answer_poss)
                all_answer_poss.push a
                break

        if question and all_answer_poss.length > 0 and actual_answer
          inst = new QuestionInstance( @
                                     , question
                                     , all_answer_poss
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