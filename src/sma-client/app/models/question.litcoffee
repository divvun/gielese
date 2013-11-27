    NoMoreProgression = require '/models/exceptions/progression_cycle_done'
    LevelComplete = require '/models/exceptions/level_complete'

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
        tries: 0

Here we find out if the user completed the question.

      cycle_for_progression: () ->
        _.max(
          (p.get('cycle') for p in app.userprogression.logs_for_question(@))
        )

How many correct answers are there for this question?

      total_correct_answers_for_question: () ->
        app.userprogression.where({
          question_correct: true
          question_category: @get('category')
          question_category_level: @get('level')
          cycle: @.get('cycle')
        }).length

      user_completed_question: (opts={}) ->
        userprogression = app.userprogression
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
          logs_for_question = userprogression.correct_logs_for_question(@)
            .filter (up) =>
              up.get('cycle') == cycle
          concepts_for_question = logs_for_question
            .map (up) ->
              up.get('question_concept')
        else
          return false

How many times was the concept correct for each question?

        concepts = @select_question_concepts app.conceptdb

For each question concept, determine what amount the user correctly,
if the amount is greater, append the correct amount to counts.
        
        correctsForCQW = (c, q, w) ->
          app.userprogression.correctLogsForConceptInQuestionInCycle(c, q, cycle).length

        counts = []
        for c in concepts
          corrects = correctsForCQW(c, @, cycle)
          if corrects > correct_count
            corrects = correct_count
          counts.push corrects

If the sum of uniq'd counts is 1, then the level/question has been completed,
and we increment the cycle one.

        # this may need to move out of here, and to somewhere else, i.e.,
        # checking whether the answer to an individual concept is correct, if
        # it is then check whether incrementing can happen, and if so return
        # about next level
        if _.uniq(counts).length == 1
          if _.max(counts) == correct_count and _.uniq(counts)[0] == correct_count
            if not opts.cycle
              console.log "incrementing cycle."
              @set('cycle', @get('cycle') + 1)
            return true

        return false

      user_completed_cycle: () ->
        userprogression = app.userprogression
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
          # TODO: rewrite to .where() once everything else is stable
          logs_for_question = userprogression.correct_logs_for_question(@)
            .filter (up) =>
              up.get('cycle') == cycle
          concepts_for_question = logs_for_question
            .map (up) ->
              up.get('question_concept')
        else
          return false

How many times was the concept correct for each question?

        concepts = @select_question_concepts app.conceptdb

For each question concept, determine what amount the user correctly,
if the amount is greater, append the correct amount to counts.
        
        correctsForCQW = (c, q, w) ->
          app.userprogression.correctLogsForConceptInQuestionInCycle(c, q, cycle).length
          
        counts = []
        for c in concepts
          corrects = correctsForCQW(c, @, cycle)
          if corrects > correct_count
            corrects = correct_count
          counts.push corrects

Here we increment the cycle if the current question is compelte

        if _.uniq(counts).length == 1
          if _.max(counts) == correct_count and _.uniq(counts)[0] == correct_count
            @set('cycle', @get('cycle') + 1)
            return true

        return false

      filter_concepts_by_media: (concepts, media_size) ->
        # TODO: fix -- use media.size, somehow
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

      select_question_concepts_by_progression: (conceptdb) ->
        userprog = app.userprogression
        orderConceptsByProgression = require './helpers/concept_progression_sorter'
        return orderConceptsByProgression(@,
          @filter_concepts_by_media(
            @select_question_concepts(conceptdb), app.media_size
          )
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
          # remove concepts that have failed before
          if concept.get('fails') == true
            return false
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

      find_concepts: (conceptdb, opts={}) ->

        if not opts.repeat_count?
          repeat_count = 0

        if repeat_count > 5
          _err = new Error()
          console.log "Uh oh"
          throw _err

        userprogression = app.userprogression
        # handle edge case for tail call immediately.
        # somehow this has failed several times, so...
        if @tries > 3
          _error_msg = "Failed generating question #{@get('category')} - #{@get('level')}"
          console.log _error_msg
          window.client_log.error(_error_msg)
          @set('fails', true)
          # TODO: recover and regenerate
          return false

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

        try
          q_concepts = @select_question_concepts_by_progression(question_concepts)
        catch err
          if err instanceof NoMoreProgression
            # check if user completed the question-- if so, then we need the
            # next level
            # increment cycle
            # go again
            if app.debug
              console.log "got NoMoreProgression..."
            if @user_completed_question()
              # next question
              throw new LevelComplete
            else
              # keep going
              return @find_concepts(conceptdb, {repeat_count: repeat_count+1})

        # Select a question concept
        if q_concepts.length > 0
          question = _.shuffle(q_concepts)[0]
          # Alternate question concepts that match the question criteria
          alternates = _.shuffle(q_concepts).slice(1)
        else
          console.log "No concepts left for question."
          console.log _filters
          return false

        # Here are the direct translations of our question prompt
        actual_answer_concepts = @filter_concepts_by_media(
          question.getTranslationsToLang(_to),
          app.media_size
        )

        if actual_answer_concepts.length == 0
          # skåajje
          _error_msg = " * No translations to #{_to} for #{question.get('concept_value')}"
          console.log _error_msg
          window.client_log.error(_error_msg)
          question.set('fails', true)
          # TODO: recover and regenerate
          @tries += 1
          return @find_concepts(conceptdb)

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
          get_canonical_concept_value = (c) =>
            question_concept_value = question.get('concept_value')
            question_lang = question.get('language')
            txls = _.first c.getTranslationsToLang(question_lang)
            return txls.get('concept_value')
        else
          chop_concept = (a) -> a
          get_canonical_concept_value = (c) -> c.get('concept_value')


        # TODO: this results in problems, image names are no longer the same, so need to
        # see if it's unique by the original concept word; if word in image translations,

        uniq_for_concept_value = (cs) =>
          _cs = []
          _cvs = []
          for c in cs
            _cv = get_canonical_concept_value c
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
          concept_values = all_answer_poss.map get_canonical_concept_value

          for c in _.range(0, difference)
            act_ans = get_canonical_concept_value(actual_answer)

            for a in _.shuffle(potential_incorrect_answers)
              pot_ans = get_canonical_concept_value(a)

              if (pot_ans != act_ans) and !(a in all_answer_poss)
                all_answer_poss.push a
                break

        if question and all_answer_poss.length > 0 and actual_answer
          concepts_left = concepts_total - q_concepts.length
          concepts_total = question_concepts.length
          inst = new QuestionInstance( @
                                     , question
                                     , all_answer_poss
                                     , actual_answer
                                     , concepts_left
                                     , concepts_total
                                     , @total_correct_answers_for_question()
                                     )

        else
          console.log " * Couldn't generate a question instance for #{@.get('name')}"
          console.log "   removing question from cycle."
          inst = false
          @.set('fails', true)

        return inst
