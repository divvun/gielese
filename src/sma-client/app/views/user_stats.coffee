CategoryLegend = require './templates/stats_category_legend'

module.exports = class UserStats extends Backbone.View

  id: "user_stats_page"

  events:
    'click .audio_link': 'findAudio'
    'click #show-panel': "revealOptionsPanel"
    'click .concept_link': 'showConcept'
    'click #logout': "logOut"

  logOut: ->
    app.loadingTracker.showLoading()
    app.auth.logout
      success: () =>
        app.loadingTracker.hideLoading()
        window.location.hash = "#reset"
    return false
  
  template: require './templates/user_stats'

  categoryChart: () ->
    # POINTS or amount of times played? 
    colors = [ "#F7464A" ,
               "#E2EAE9" ,
               "#D4CCC5" ,
               "#949FB1" ,
               "#4D5360" ]

    values = [ 30
             , 50
             , 100
             , 40
             , 120
             ]

    catego = [ "FOOD"
             , "BODYPART"
             , "GREETINGS"
             , "Category #4"
             , "Category #5"
             ]

    data = [ { value : 30,  color:"#F7464A" },
             { value : 50,  color : "#E2EAE9" },
             { value : 100, color : "#D4CCC5" },
             { value : 40,  color : "#949FB1" },
             { value : 120, color : "#4D5360" }]

    category_colors = []
    for [cat, col] in _.zip(catego, colors)
      logs = app.leksaUserProgression
                .filter (q) =>
                   q.get("question").category is cat if q.get("question")?

      _points = logs.map (l) -> l.get('points')
      points = _.reduce(_points, ((memo, num) -> memo + num), 0)

      category_colors.push {name: cat, color: col, points: points}

    # sort by points?
    data = []
    for cat in category_colors
      data.push {
        value: cat.points
        color: cat.color
      }

    ctx = @$el.find('#category_use')[0].getContext('2d')
    chart = new Chart(ctx).Doughnut(data, {
      animation: false,
    })

    @$el.find('#categories').html CategoryLegend {
      items: category_colors
    }

    console.log category_colors

  render: ->

    # * word accuracy rate
    # * category accuracy rate
    # * words to practice
    # * percentage of time spent on each category-- see what needs doing (fancy pie chart?)
    #
    # but for now, just a list of objects
    models = app.leksaUserProgression.models
    console.log "wtf #{ models.length }"

    correct_for_category = {}
    if app.leksaUserProgression.length > 0
      # problem here
      questions = app.leksaUserProgression
                     .pluck('question')
                     .filter (q) ->
                       q != null

      cats = []

      cats.push cat for cat in cats if cat?
      
      categories = _.uniq cats

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

    if app.leksaUserProgression.length > 0
      @categoryChart()


