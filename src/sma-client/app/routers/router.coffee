# TODO: clean up all this.
#
# TODO: additional issue is that some views need to be reinstantiated
#       in order for all events to be available again, as
#       router.changePage destroys them for some reason.

LeksaView = require 'views/leksa_view'
CategoryGames = require 'views/category_games_view'
ConceptList = require 'views/concept_list'
GlobalOptionsView = require 'views/global_options'

UserStats = require 'views/user_stats'
CategoryMenu = require 'views/category_view'
CategoryGames = require 'views/category_games_view'
FrontPage = require 'views/front_page'
LeksaOptionsView = require 'views/leksa_options_view'
ErrorView = require 'views/error_view'
LoadingView = require 'views/loading'

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
    app.leksaOptionsView = new LeksaOptionsView()
    app.frontPage = new FrontPage()
    app.loadingView = new LoadingView()

  # Seems to be no way to avoid the double listing for now, because of hash
  # option, which does some funky redirecting.
  routes:
    '': 'index'
    '#index': 'index'

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

    # First step

    'mainMenu':  'categoryMenu'
    '#mainMenu': 'categoryMenu'

    'categoryMenu':  'categoryMenu'
    '#categoryMenu': 'categoryMenu'

    'category/:name':  'categoryGames'
    '#category/:name': 'categoryGames'

    #

    'leksa/:category': 'leksa'
    '#leksa/:category': 'leksa'

    'leksa/:level/:category': 'leksa_first'
    '#leksa/:level/:category': 'leksa_first'

    'leksaOptions': 'leksaOptions'
    '#leksaOptions': 'leksaOptions'

    'wordlist': 'wordlist'
    '#wordlist': 'wordlist'

    # omg.

    'concept/:id': 'conceptView'
    '#concept/:id': 'conceptView'

    'conceptSet/:category': 'conceptSet'
    '#conceptSet/:category': 'conceptSet'

  index: ->
    c = 0
    # while not app.loadingTracker.isReady()
    #   console.log c
    #   c += 1

    # app.loadingTracker.hideLoading()

    configured_already = DSt.get('gielese-configured')
    if configured_already
      @changePage(app.categoryMenu)
    else
      @changePage(app.frontPage)
  
  loading: ->
    @changePage(app.loadingView)

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

  leksaOptions: ->
    app.loadingTracker.checkDeps()
    @changePage(app.leksaOptionsView)

  leksa: (category) ->
    # $('content #content').html app.leksaView.render().el
    # ready = false
    # until ready
    app.loadingTracker.checkDeps()

    app.leksaView = new LeksaView()
    app.leksaView.leksa_category = category
    app.leksaView.initialize()

    @changePage(app.leksaView)

    app.leksaView.viewedOnce = true
    
  leksa_first: (level, category) ->
    # $('content #content').html app.leksaView.render().el
    # ready = false
    # until ready
    app.loadingTracker.checkDeps()

    level = parseInt level
    app.leksaView = new LeksaView()
    app.leksaView.leksa_category = category
    if level == 1
      app.leksaView.level_constraint = (question) =>
        question.get('level') == level
    else if level > 1
      app.leksaView.level_constraint = (question) =>
        question.get('level') >= level
      
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
    app.conceptList = new ConceptList()
    app.conceptList.for_category = category
    app.conceptList.initialize()
    @changePage(app.conceptList)

  wordlist: ->
    # $('content #content').html app.leksaView.render().el
    app.conceptList = new ConceptList()
    app.conceptList.for_category = "BODYPART"
    app.conceptList.initialize()
    @changePage(app.conceptList)

  conceptView: (id) ->
    app.conceptView.initialize(id)
    @changePage(app.conceptView)

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

    window.omg = page.el
    $.mobile.changePage($(page.el), {changeHash:false, transition:transition})
    return false

