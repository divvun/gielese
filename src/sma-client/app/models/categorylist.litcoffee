The category list maintains all the dependencies of the main word categories,
and uses them to generate the main menu. It is also useful in determining
concept sets used in question generation.

    Category = require 'models/category'

    module.exports = class CategoryList extends Backbone.Collection
      model: Category

The URL for the "remote" collection depends on what mode the application is
running in. `app.server.offline_media` will be set for mobile app versions, in
which case the "remote" collection is really stored locally. The web app will
search for data on the server hostname.

      url: () ->
        if app.server.offline_media
          return "data/categories.json"
        return app.server.path + "/data/categories.json"

Initialize the collection, and fetch the categories from the server. If
successful, mark off progress in the loading tracker otherwise error. Three
attempts are made.

      initialize: () ->
        @fetch_tries = 0
        @max_tries = 3

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
            if @fetch_tries < @max_tries
              @fetch()
            else
              console.log "Tried fetching categories.json too many times"

Determine where the categories are stored in the response.

      parse: (response, opts) ->
        return response.categories

