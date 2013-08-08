QuestionTests = require './question_tests'
AuthTests = require './auth_tests'

module.exports = class Tests
  constructor: ->
    @questions = new QuestionTests()
    @auth = new AuthTests()
