
module.exports = class UserStats extends Backbone.View

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    'click .concept_link': 'showConcept'
  
  template: require './templates/user_stats'

  render: ->

    # * word accuracy rate
    # * category accuracy rate
    # * words to practice
    #
    # but for now, just a list of objects
    models = app.leksaUserProgression.models
    console.log "wtf #{ models.length }"
    categories = _.uniq (q.category for q in app.leksaUserProgression.pluck('question'))
    console.log categories
    correct_for_category = {}
    for c in categories
      questions_for_category = app.leksaUserProgression.filter (l) =>
        l.get('question').category == c
      questions_correct_for_category = questions_for_category.filter (l) =>
        l.get('question_correct') == true
      
      total_questions_tried = questions_for_category.length
      total_questions_correct = questions_correct_for_category.length

      correct_for_category[c] = {
        'total': total_questions_tried
        'correct': total_questions_correct
        'percent': (total_questions_correct/total_questions_tried)*100
      }

    @$el.html @template
      logs: models
      category_scores: correct_for_category


