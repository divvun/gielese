The category list maintains all the dependencies of the main word categories,
and uses them to generate the main menu.

    Category = require 'models/category'

    module.exports = class CategoryList extends Backbone.Collection
      model: Category

      url: (offline = false) ->
        if offline
          return "data/categories.json"
        return app.server.path + "/data/categories.json"

      parse: (response, opts) ->
        return response.categories

      initialize: () ->
          # @storage = new Offline.Storage('word-categories', @)
