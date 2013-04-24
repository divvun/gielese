
Question = require 'models/question'

module.exports = class QuestionDB extends Backbone.Collection
  model: Question

