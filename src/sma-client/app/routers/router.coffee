
module.exports = class Router extends Backbone.Router

  initialize: () ->
      # Handle back button throughout the application
      $('.back').live 'click', (event) ->
          window.history.back()
          return false
      @firstPage = true

  routes:
    '': 'index'
    'leksa': 'leksa'
    'wordlist': 'wordlist'
    'options': 'options'
    'error': 'errorPage'

    'home': 'index'
    '#': 'index'
    '#home': 'index'
    '#wordlist': 'wordlist'
    '#leksa': 'leksa'
    '#options': 'options'
    '#error': 'errorPage'

  index: ->
    ##  $('content #content').html app.helloView.render().el
    @changePage(app.helloView)

  leksa: ->
    # $('content #content').html app.leksaView.render().el
    @changePage(app.leksaView)

  errorPage: ->
    # $('content #content').html app.errorView.render().el
    @changePage(app.errorView)

  options: ->
    @changePage(app.globalOptionsView)

  wordlist: ->
    # $('content #content').html app.leksaView.render().el
    @changePage(app.conceptList)

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

