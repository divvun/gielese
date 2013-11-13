# TODO: if this view is called and someone isn't logged in, display login
# but with a back button
#
CategoryLegend = require './templates/category_legend'
HighScoreList = require './templates/high_scores'

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
  
  template: require './templates/stats'

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
                  q.get("question_category") is cat if q.get("question_category")?

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

  store_user_visibility: (evt, ui) ->
    toBool = (v) ->
      switch v
        when "true"  then return true
        when "false" then return false

    key = 'highscore_visible'
    val = toBool $(evt.target).attr('data-highscore-visible')

    if app.user
      app.options.setSettings({highscore_visible: val}, {store: true})

    return false

  render: ->

    # * word accuracy rate
    # * category accuracy rate
    # * words to practice
    # * percentage of time spent on each category-- see what needs doing (fancy
    #   pie chart?)
    #
    # but for now, just a list of objects
    models = app.leksaUserProgression.models

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

    if app.leksaUserProgression.length > 0
      points = app.leksaUserProgression.countPoints()
    else
      points = false

    user = false
    if app.user
      user = true

    @$el.html @template
      logs: models
      category_scores: correct_for_category
      highscore_visible: app.options.getSetting('highscore_visible')
      points_total: points
      user: user

    if app.leksaUserProgression.length > 0
      @categoryChart()

    @$el.find('#display_stats input[type=radio]').on(
      'change',
      @store_user_visibility
    )

    scores = @$el.find('div#high_scores')
    $.get '/users/scores/',
      (resp) =>
        scores.html HighScoreList
          highscores: resp.highscores

