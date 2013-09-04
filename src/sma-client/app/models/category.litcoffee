Category model.

    module.exports = class Category extends Backbone.Model

Compatibility with old version of bootstrap

      idAttribute: "c_id"

      defaults:
        children: []
        activities: [ ]

      initialize: () ->

      children: () ->
        cs = @.get('children')
        if cs.length == 0
          return false
        else
          return (new Category c for c in cs)

      hasImage: (opts = {}) ->
        if not opts.device
          device = app.device_type
        else
          device = opts.device
    
        if not opts.size
          size = "small"
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

