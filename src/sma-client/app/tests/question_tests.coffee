module.exports = class QuestionTests
  test_order: [
    'duplicate_four_questions'
  ]

  duplicate_four_questions: ->
    # Create a specific type of question and inspect the kinds of values it
    # presents
    #
    db = app.questiondb
    errors = []
    success = true

    vs = db.where({type: "word_to_image", category: "TEST"})[0]
      .find_concepts(app.conceptdb, app.leksaUserProgression)
      .choices
      .map (o) -> o.attributes.concept_value

    filenames = vs.map (a) -> a.split('/').slice(-1)[0]

    if _.uniq(filenames).length != 4
      console.log filenames
      success = false
      errors.push "* Filenames are same, directory structure differs"

    if _.uniq(vs).length != 4
      console.log vs
      success = false
      errors.push "* Paths are the same"

    return [success, errors]

  run: (iterations = 4) ->

    status_str = (a) ->
      if a
        "PASS"
      else
        "FAIL"

    _th = @
    for a in @test_order
      [status, errors] = _th[a]()
      console.log "#{status_str(status)}: #{a}"
      if errors.length > 0
        for err in errors
          console.log "  #{err}"
      
  constructor: ->
      
