HelloView = require 'views/hello_view'
LeksaView = require 'views/leksa_view'
ConceptList = require 'views/concept_list'

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

  index: ->
    ##  $('content #content').html app.helloView.render().el
    @changePage(new HelloView())

  leksa: ->
    # $('content #content').html app.leksaView.render().el
    @changePage(new LeksaView())

  wordlist: ->
    # $('content #content').html app.leksaView.render().el
    @changePage(app.conceptList)

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

