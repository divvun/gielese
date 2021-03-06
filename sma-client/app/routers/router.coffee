
# Including views in `application.coffee` was getting to be too messy, so 
# initialized views will be stored around here. 

# NB: some views need to be reinstantiated in order for all events to be
# available again, as router.changePage destroys them for some reason.

# NB: There were some compatibility issues at one point or another, regarding
# whether URLs were anchors (with #hash) pattern, or just bare URLs. For the
# sake of compatibility with this potential situation, don't remove these, it's
# possible to confirm that this will not be problematic on any devices.

LeksaView = require 'views/games/leksa'
LearnView = require 'views/games/learn'

CategoryMenu = require 'views/categories/categories'
CategoryGames = require 'views/categories/category'

ConceptList = require 'views/concepts/list'
GlobalOptionsView = require 'views/users/options'

UserStats = require 'views/users/stats'
FrontPage = require 'views/intro/view'
ErrorView = require 'views/error/view'
LoadingView = require 'views/intro/loading'
SplashView = require 'views/splash/splash'
InfoView = require 'views/info/info'
LevelComplete = require 'views/games/level_complete'

module.exports = class Router extends Backbone.Router

  initialize: () ->
    # Handle back button throughout the application
    $('.back').live 'click', (event) ->
      window.history.back()
      return false
    @firstPage = true

    app.userStats = new UserStats()
    app.categoryMenu = new CategoryMenu()
    app.categoryGames = new CategoryGames()
    app.errorView = new ErrorView()
    app.frontPage = new FrontPage()
    app.loadingView = new LoadingView()
    app.splashView = new SplashView()
    app.infoView = new InfoView()
    app.levelComplete = new LevelComplete()

  # Seems to be no way to avoid the double listing for now, because of hash
  # option, which does some funky redirecting.
  routes:
    '': 'splash'
    '#splash': 'splash'

    'index': 'index'
    '#index': 'index'

    'frontPage': 'frontPage'
    '#frontPage': 'frontPage'

    # Misc
    
    'options': 'options'
    '#options': 'options'

    'error': 'errorPage'
    '#error': 'errorPage'

    'reset': 'reset'
    '#reset': 'reset'

    'loading': 'loading'
    '#loading': 'loading'

    'stats':  'userStats'
    '#stats': 'userStats'

    'infoPage': 'infoPage'
    '#infoPage': 'infoPage'

    # First step

    'mainMenu':  'categoryMenu'
    '#mainMenu': 'categoryMenu'

    'categoryMenu':  'categoryMenu'
    '#categoryMenu': 'categoryMenu'

    'category/:name':  'categoryGames'
    '#category/:name': 'categoryGames'

    #

    'level_complete': 'level_complete'
    '#level_complete': 'level_complete'

    'category_complete': 'category_complete'
    '#category_complete': 'category_complete'

    'leksa/:level/:category': 'learn_and_practice'
    '#leksa/:level/:category': 'learn_and_practice'

    'conceptSet/:category': 'conceptSet'
    '#conceptSet/:category': 'conceptSet'

  index: ->
    configured_already = DSt.get('gielese-configured')
    if configured_already
      @changePage(app.categoryMenu)
    else
      app.frontPage = new FrontPage()
      @changePage(app.frontPage)

  frontPage: ->
    app.frontPage = new FrontPage()
    @changePage(app.frontPage)
  
  loading: ->
    @changePage(app.loadingView)

  infoPage: ->
    @changePage(app.infoView)

  level_complete: ->
    app.levelComplete = new LevelComplete()
    app.levelComplete.category = false
    @changePage(app.levelComplete)

  category_complete: ->
    app.levelComplete = new LevelComplete()
    app.levelComplete.category = true
    @changePage(app.levelComplete)

  splash: ->
    @changePage(app.splashView)
    # for testing
    # return false
    # Skip splash if dev setting is set, or if running in phonegap
    
    if DSt.get('skip-splash')?
      time = 500
    else
      time = 5000

    if window.PhoneGapIndex and navigator.splashscreen?
      configured_already = DSt.get('gielese-configured', false)
      if configured_already and app.user
        app.categoryMenu = new CategoryMenu()
        @fadePage(app.categoryMenu)
      else
        app.frontPage = new FrontPage()
        @fadePage(app.frontPage)
    else
      setTimeout(() =>
        configured_already = DSt.get('gielese-configured', false)
        if configured_already and app.user
          app.categoryMenu = new CategoryMenu()
          @fadePage(app.categoryMenu)
        else
          app.frontPage = new FrontPage()
          @fadePage(app.frontPage)
      , time)

  reset: ->
    DSt.set('gielese-configured', false)
    window.location = '/'

  userStats: ->
    # TODO: logged in testing only
    app.userStats = new UserStats()
    @changePage(app.userStats)

  categoryMenu: ->
    app.categoryMenu = new CategoryMenu()
    app.categoryMenu.initialize()
    @changePage(app.categoryMenu)

  categoryGames: (name) ->

    app.categoryGames = new CategoryGames()
    app.categoryGames.category = name
    app.categoryGames.initialize()

    @changePage(app.categoryGames)

  learn_and_practice: (level, category) ->
    # $('content #content').html app.leksaView.render().el
    # ready = false
    # until ready
    app.loadingTracker.waitForDeps
      extra_test: () =>
        app.conceptdb.models.length > 0 \
          and app.questiondb.models.length > 0 \
          and app.categories.models.length > 0
      failed: () =>
        # TODO: error view / caching problem or server not up
        console.log "Uh oh!"
      ready: () =>

        level = parseInt level
    
        if level == 1
          app.leksaView = new LearnView
            attributes:
              leksa_category: category
              level_constraint: level
        else if level > 1
          app.leksaView = new LeksaView
            attributes:
              leksa_category: category
              level_constraint: level
         
        app.leksaView.preselected_q = app.leksaView.selectQuestionForRendering()
        #
        # Hopefully we're still in the click event here, in which case we need
        # to play now.
        app.leksaView.pregenerated = true
        app.leksaView.playQuestionSound()
    
        app.leksaView.initialize()
    
        @changePage(app.leksaView)
    
        app.leksaView.viewedOnce = true

  errorPage: ->
    # $('content #content').html app.errorView.render().el
    @changePage(app.errorView)

  options: ->
    app.globalOptionsView = new GlobalOptionsView()
    @changePage(app.globalOptionsView)

  conceptSet: (category) ->
    # $('content #content').html app.leksaView.render().el
    app.loadingTracker.waitForDeps
      extra_test: () =>
        app.conceptdb.models.length > 0
      ready: () =>
        app.conceptList = new ConceptList()
        app.conceptList.for_category = category
        app.conceptList.initialize()
        @changePage(app.conceptList)
      failed: () =>
        # TODO: error view / caching problem or server not up
        console.log "Oh craapp"

  refreshCurrentPage: () ->
    $('[data-role="page"]').trigger("pagecreate")
    return true

  changePage: (page) ->
    # Here we're creating new change page behavior so that backbone plays
    # nicely with jQuery mobile.
    #
    $(page.el).attr('data-role', 'page')
    page.render()

    $('body').append($(page.el))
    transition = $.mobile.defaultPageTransition

    # We don't want to slide the first page
    if @firstPage
      transition = 'none'
      @firstPage = false

    $.mobile.changePage($(page.el), {changeHash:false, transition:transition})
    return false

  fadePage: (page) ->
    # Here we're creating new change page behavior so that backbone plays
    # nicely with jQuery mobile.
    #
    $(page.el).attr('data-role', 'page')
    page.render()

    $('body').append($(page.el))
    transition = $.mobile.defaultPageTransition

    transition = 'fade'

    $.mobile.changePage($(page.el), {changeHash:false, transition:transition})
    return false
