The category list maintains all the dependencies of the main word categories,
and uses them to generate the main menu.

    Category = require 'models/category'

    module.exports = class CategoryList extends Backbone.Collection
      model: Category

      url: () ->
        if app.server.offline_media
          return "data/categories.json"
        return app.server.path + "/data/categories.json"

      parse: (response, opts) ->
        return response.categories

      initialize: () ->
        @fetch_tries = 0
        # @storage = new Offline.Storage('word-categories', @)
        @fetch
          success: () =>
            window.fetched_somewhere = true
            app.loadingTracker.markReady('categories.json')
            console.log "fetched categories.json (#{app.conceptdb.models.length})"
            app.categories.offline = false
          error: () ->
            if app.debug
              console.log "Error fetching categories.json"
            @fetch_tries += 1
            if @fetch_tries < 3
              @fetch()
            else
              console.log "Tried fetching categories.json too many times"
