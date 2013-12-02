Category model.

    module.exports = class Category extends Backbone.Model

Compatibility with old version of bootstrap

      idAttribute: "c_id"

      defaults:
        children: []
        activities: [ ]

      initialize: () ->

      getConcepts: (args = {}) ->
        query = _.extend {semantics: @get('semantics')}, args
        concepts = app.conceptdb.where(query)

        if @attributes.order_by?
          _order = @attributes.order_by
          sorter = (a) =>
            _a_attr = a.attributes || {}
            _a_ext = _a_attr.extra_attributes || {}
            _a_ord = _a_ext[_order]
            return _a_ord
        else
          sorter = (c) -> c.get('concept_value')

        sorted = _.sortBy concepts, sorter

        return sorted

      children: () ->
        cs = @.get('children')
        if cs.length == 0
          return false
        else
          return (new Category c for c in cs)

The category image is selected from media.
      
      hasThumbnail: (opts = {}) ->
        if not opts.device
          device = app.device_type
        else
          device = opts.device
    
        if not opts.size
          size = app.media_size
        else
          size = opts.size
        
        # TODO: maybe preference to image size over device? i.e., if large/tablet
        # doesn't exist, but large/mobile does, take that one
        has_media = @.get('media')

        if not has_media?
          return false

        if 'icon' of has_media
          if has_media.icon.length > 0
    
            images_for_device = _.filter has_media.icon, (i) ->
              return i.size == size and i.device == device
    
            if images_for_device.length == 0
              return has_media.icon[0].path
    
            if images_for_device.length > 0
              return images_for_device[0].path
    
            return images_for_device
        return false

      hasImage: (opts = {}) ->
        if not opts.device
          device = app.device_type
        else
          device = opts.device
    
        if not opts.size
          size = app.media_size
        else
          size = opts.size
    
        console.log [device, size]
        # TODO: maybe preference to image size over device? i.e., if large/tablet
        # doesn't exist, but large/mobile does, take that one
        has_media = @.get('media')

        if not has_media?
          return false

        if 'image' of has_media
          if has_media.image.length > 0
    
            images_for_device = _.filter has_media.image, (i) ->
              return i.size == size and i.device == device
    
            if images_for_device.length == 0
              return has_media.image[0].path
    
            if images_for_device.length > 0
              return images_for_device[0].path
    
            return images_for_device
        return false

