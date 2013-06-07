LeksaView = require 'views/leksa_view'
ConceptList = require 'views/concept_list'

module.exports = class Router extends Backbone.Router

  initialize: () ->
      # Handle back button throughout the application
      $('.back').live 'click', (event) ->
          window.history.back()
          return false
      @firstPage = true

  # Seems to be no way to avoid the double listing for now, because of hash
  # option, which does some funky redirecting.
  routes:
    '': 'index'

    'home': 'index'
    '#home': 'index'

    'mainMenu': 'mainMenu'
    '#mainMenu': 'mainMenu'

    'leksa/:category': 'leksa'
    '#leksa/:category': 'leksa'

    'leksaOptions': 'leksaOptions'
    '#leksaOptions': 'leksaOptions'

    'wordlist': 'wordlist'
    '#wordlist': 'wordlist'

    'options': 'options'
    '#options': 'options'

    'error': 'errorPage'
    '#error': 'errorPage'

    # omg.
    'concept/:id': 'conceptView'
    '#concept/:id': 'conceptView'

    'conceptSet/:category': 'conceptSet'
    '#conceptSet/:category': 'conceptSet'

    'reset': 'reset'
    '#reset': 'reset'

    'leksaSelect': 'leksaSelect'
    '#leksaSelect': 'leksaSelect'

    'loading': 'loading'
    '#loading': 'loading'

  index: ->
    c = 0
    # while not app.loadingTracker.isReady()
    #   console.log c
    #   c += 1

    # app.loadingTracker.hideLoading()

    configured_already = DSt.get('gielese-configured')
    if configured_already
      @changePage(app.helloView)
    else
      @changePage(app.frontPage)
  
  loading: ->
    @changePage(app.loadingView)

  reset: ->
    DSt.set('gielese-configured', false)
    window.location = '/'

  mainMenu: ->
    ##  $('content #content').html app.helloView.render().el
    @changePage(app.helloView)

  leksaOptions: ->
    window.app.loadingTracker.checkDeps()
    @changePage(app.leksaOptionsView)

  leksa: (category) ->
    # $('content #content').html app.leksaView.render().el
    # ready = false
    # until ready
    window.app.loadingTracker.checkDeps()

    app.leksaView = new LeksaView()
    app.leksaView.leksa_category = category
    app.leksaView.initialize()

    @changePage(app.leksaView)

    app.leksaView.viewedOnce = true

  errorPage: ->
    # $('content #content').html app.errorView.render().el
    @changePage(app.errorView)

  leksaSelect: ->
    @changePage(app.leksaSelectView)

  options: ->
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

