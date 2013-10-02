﻿Helpful TODOs at end of module...

# Helper function for user progression concept sorting

The point of this piece is to integrate the user progression with the way that
concepts are selected for a given question, taking into account the following
things: 

1.) How many times has the question concept been displayed?
  - More than four times? -> Remove!
  - Less than four times? -> Sort by display count.

2.) What was the last question concept displayed?

3.) Is there a user progression?

4.) Is the user done with all of the concepts in the progression?

So, let's get going... Define the module as a function expect a `question`,
list of `concepts`, and the `userprogression`.

    module.exports = orderConceptsByProgression = (q, concepts, up) ->

Grab only the user progression for this question.

      userprogression = up.filter (u) =>
        u.get('question').cid == q.cid

      if app.debug
        console.log "#{q.cid} - #{userprogression.length} run-throughs"

If there's nothing in the user progression, great, no need to sort!

      if userprogression.length == 0
        return concepts

      max_repeats = _.max (u.get('cycle') for u in userprogression)

      if not max_repeats
        max_repeats = false

      if app.debug
        console.log "Currently at cycle <#{max_repeats}>"

For a user progression, figure out how many times this question concept has
been answered as correct by the user.

      getProgressionCorrectCountForConcept = (c) =>
        zups = userprogression
          .filter (up) =>
            up.get('question') == q
          .filter (up) =>
            up.get('question_concept') == c.get('id')
          .filter (up) =>
            up.get('question_correct')
        if max_repeats
          zups = zups.filter (up) =>
            up.get('cycle') == max_repeats
        return zups.length

Remove a concept from the cycle once it has been displayed 4 times.

      if q.get('repetitions')
        reps = parseInt q.get('repetitions')
        if app.debug
          console.log "question repetition count:" + q.get('repetitions')
      else
        reps = 3
        if app.debug
          console.log "question repetition not specified, default 3"

      countLessRepetitions = (c) =>
        getProgressionCorrectCountForConcept(c) < reps + 1

Try to avoid repeats by excluding the last concept from the progression.

      last_concept = up.last()
      if app.debug
        console.log "Last concept: "
        console.log last_concept

      if last_concept
        notLast = (c) =>
          c.get('concept_value') != last_concept.get('question_concept_value')
        excluding_last_concept = _.filter(concepts, notLast)

        if excluding_last_concept.length == 0
          excluding_last_concept = concepts
      else
        excluding_last_concept = concepts

Now we sort by the amount of times the concept has been displayed-- giving
preference to those that have been displayed less so far.

      ordered_by_frequency = _.sortBy(
        _.filter(excluding_last_concept, countLessRepetitions),
        getProgressionCorrectCountForConcept
      )

Useful debugging info...

      if app.debug
        f_strings = ordered_by_frequency.map (f) ->
            "#{getProgressionCorrectCountForConcept(f)} - #{f.get('concept_value')}"

        if f_strings.length > 0
          console.log f_strings.join('\n')

Here there may be a problem that there are no concepts fitting the progression,
which means most likely that the user has completed the level. So, we return
something anyway, but log an error.

      if ordered_by_frequency.length == 0
        if app.debug
          console.log "No more concepts fitting progression"
        return concepts

      ordered_by_frequency

# TODO:

Maybe it's worth only considering the user progression of the last hour, or
something like that?
