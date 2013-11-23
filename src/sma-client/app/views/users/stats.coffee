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

  initChart: () ->
    width = 960
    height = 500
    radius = Math.min(width, height) / 2

    color = d3.scale.category20()

    pie = d3.layout.pie()
        .value( (d) -> return d.count )
        .sort(null)

    arc = d3.svg.arc()
        .innerRadius(radius - 100)
        .outerRadius(radius - 20)


    svg = d3.select(_el).append("svg")
        .attr("width", width)
        .attr("height", height)
      .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")")

    path = svg.selectAll("path")

    return svg

  categoryChart: () ->
    # POINTS or amount of times played?
    catego = app.categories.pluck('category')
    color_range = [ "#F7464A" ,
                    "#E2EAE9" ,
                    "#D4CCC5" ,
                    "#949FB1" ,
                    "#4D5360" ]

    test_data = [ { points: 30,  color:"#F7464A", category: "omg" },
                  { points: 50,  color: "#E2EAE9", category: "bbq" },
                  { points: 100, color: "#D4CCC5", category: "lol" },
                  { points: 40,  color: "#949FB1", category: "foo" },
                  { points: 120, color: "#4D5360", category: "bar" }]

    category_colors = []
    for [cat, col] in _.zip(catego, color_range)
      logs = app.leksaUserProgression
                .filter (q) =>
                  q.get("question_category") is cat if q.get("question_category")?

      _points = logs.map (l) -> l.get('points')
      points = _.reduce(_points, ((memo, num) -> memo + num), 0)

      category_colors.push {category: cat, color: col, points: points}

    if app.debug
      console.log category_colors
    if app.debug and app.leksaUserProgression.models.length == 0
      category_colors = test_data
      console.log category_colors

    # TODO: legend
    # @$el.find('#categories').html CategoryLegend {
    #   items: category_colors
    # }

    width = $(document).width() - 20
    height = 300
    radius = Math.min(width, height) / 2

    color = d3.scale.ordinal().range(color_range)

    arc = d3.svg.arc().outerRadius(radius - 10)
                      .innerRadius(radius - 70)

    pie = d3.layout.pie().sort(null).value (d) -> d.points

    _el = @$el.find("#category_use")[0]
    if $(_el).find('svg')
      $(_el).find('svg').remove()

    svg = d3.select(_el)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")")

    plotCategories = (data) ->

      data.forEach (d) ->
        d.points = +d.points

      g = svg.selectAll(".arc")
             .data(pie(data))
             .enter().append("g").attr("class", "arc")

      g.append("path").attr("d", arc).style "fill", (d) ->
        color d.data.category

      g.append("text").attr("transform", (d) ->
        "translate(" + arc.centroid(d) + ")"
      ).attr("dy", ".35em").style("text-anchor", "middle").text (d) ->
        d.data.category

    plotCategories(category_colors)
    return true

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

    if app.leksaUserProgression.length > 0 or app.debug
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

