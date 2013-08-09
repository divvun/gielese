QuestionTests = require './question_tests'
AuthTests = require './auth_tests'

module.exports = class Tests
  test_order: [
    'questions'
    'auth'
  ]

  run: ->
    true

  constructor: ->
    @questions = new QuestionTests()
    @auth = new AuthTests()
