This module is somewhat complex, thus it is written in Literate Coffeescript.

This class is returned when a question is generated.

    class QuestionInstance
      constructor: (@generator, @question, @choices, @answer, @current_count,
                    @question_total, @total_correct) ->
        if app.debug
          console.log "created instance"
        if app.debug
          console.log "cIDs for answer concepts:"
          console.log (choice.cid for choice in @choices)
        @choices = _.shuffle(@choices)

## Question model

This is the only thing we need to export from this module.

    module.exports = class Question extends Backbone.Model

Determine whether the user has completed this question, here, defined as
answering all concepts in level correctly at least once.

      defaults:
        cycle: 1

Here we find out if the user completed the question.

      find_cycle_for_progression: (userprog) ->
        logs_for_question = userprog
            .filter (up) =>
              up? and up.get('question').cid?
            .filter (up) =>
              up.get('question') and (up.get('question').cid == @cid)
        return _.max(
          (p.get('cycle') for p in logs_for_question)
        )
        
      user_completed_question: (opts={}) ->
        userprogression = app.leksaUserProgression
        correct_count = 2

        if opts.cycle
          cycle = opts.cycle
        else
          cycle = @get('cycle')

Filter user progression models for the current cycle, question ID, whether it
was correct. Then return all the question concepts for these logs.

        # this only checks the current cycle, which should be incremented
        # and stored unless user logs back in again
        if userprogression.length > 0
          logs_for_question = userprogression
              .filter (up) =>
                up?
              .filter (up) =>
                up.get('question') and (up.get('question').cid == @cid)
              .filter (up) =>
                up.get('cycle') == cycle
              .filter (up) ->
                up.get('question_correct') == true
          concepts_for_question = logs_for_question
              .map (up) ->
                up.get('question_concept')
        else
          return false

How many times was the concept correct for each question?

        getProgressionCorrectCountForConcept = (c) =>
          userprogression
            .filter (up) =>
              up.get('question_concept') == c.get('id')
            .filter (up) =>
              up.get('cycle') == cycle
            .filter (up) =>
              up.get('question_correct')
            .filter (up) =>
              up.get('question').cid == @cid
            .length
        
        concepts = @select_question_concepts app.conceptdb

For each question concept, determine what amount the user correctly,
if the amount is greater, append the correct amount to counts.
        
        counts = []
        for c in concepts
          corrects = getProgressionCorrectCountForConcept(c)
          if corrects > correct_count
            corrects = correct_count
          counts.push corrects

If the sum of uniq'd counts is 1, then the level/question has been completed,
and we increment the cycle one.

        if _.uniq(counts).length == 1
          if _.max(counts) == correct_count and _.uniq(counts)[0] == correct_count
            if not opts.cycle
              console.log "incrementing cycle"
              @set('cycle', @get('cycle') + 1)
            return true

        return false

      filter_concepts_by_media: (concepts, media_size) ->
        _ms = "/#{media_size}/"
        filtered_concepts = _.filter concepts, (c) =>
          if c.get('language') == 'img'
            ## imgs = c.get('media').image
            ## imgs_fit = (i for i in imgs if i.size == media_size)
            ## console.log imgs_fit
            return c.get('concept_value').search(_ms) > -1
          else
            return true

        if filtered_concepts.length == 0
          if app.debug
            console.log "* Unable to filter by media type because concepts do not"
            console.log "  have a media type that matches device. Falling back to"
            console.log "  whatever is available."
          return concepts

        return filtered_concepts

      select_question_concepts_by_progression: (conceptdb, userprog) ->
        orderConceptsByProgression = require './helpers/concept_progression_sorter'
        return orderConceptsByProgression(@,
          @filter_concepts_by_media(
            @select_question_concepts(conceptdb), app.media_size
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

        if @attributes.type == 'word_to_image'
          question_concepts = @filter_concepts_by_media(question_concepts, app.media_size)

        q_concepts = @select_question_concepts_by_progression(
          question_concepts,
          userprogression
        )

        total_correct_answers_for_question = userprogression.where({
            game_name: "leksa"
            question_correct: true
            question: @
            cycle: @.get('cycle')
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
        actual_answer_concepts = @filter_concepts_by_media(
          question.getTranslationsToLang(_to),
          app.media_size
        )

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

        answer_possibilities = @filter_concepts_by_media(answer_possibilities, app.media_size)

        answer_possibilities = answer_possibilities.slice(0, max_answers - 1)

        all_answer_poss = [actual_answer]
        all_answer_poss = all_answer_poss.concat answer_possibilities
        all_answer_poss = uniq_for_concept_value all_answer_poss

Fill the array with missing answers if we have too few.

        if all_answer_poss.length < max_answers
          if app.debug
            console.log "Things came short, filling in..."
          
          difference = max_answers - all_answer_poss.length
          concept_values = (a.attributes.concept_value for a in all_answer_poss).map chop_concept

          for c in _.range(0, difference)
            act_ans = chop_concept(actual_answer.attributes.concept_value)

            for a in _.shuffle(potential_incorrect_answers)
              pot_ans = chop_concept(a.attributes.concept_value)

              if (pot_ans != act_ans) and !(a in all_answer_poss)
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
