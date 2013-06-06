exports.config =
  # See docs at http://brunch.readthedocs.org/en/latest/config.html.
  files:
    javascripts:
      defaultExtension: 'coffee'
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^vendor/
        'test/javascripts/test.js': /^test(\/|\\)(?!vendor)/
        'test/javascripts/test-vendor.js': /^test(\/|\\)(?=vendor)/
      order:
        before: [
          'vendor/scripts/console-helper.js'
          'vendor/scripts/soundmanager2-jsmin.js'
          'vendor/scripts/DSt.js'
          'vendor/scripts/jquery-1.7.2.js'
          'vendor/scripts/jquery-ui-1.10.3.custom.min.js'
          'vendor/scripts/jquery.mobile.init.js'
          'vendor/scripts/jquery.mobile-1.3.1.min.js'
          'vendor/scripts/jquery.cookie.js'
          'vendor/scripts/underscore-1.3.3.js'
          'vendor/scripts/backbone.js'
          
          # https://github.com/jeromegn/Backbone.localStorage
          'vendor/scripts/backbone.localStorage.js'
        ]
    stylesheets:
      defaultExtension: 'styl'
      joinTo: 'stylesheets/app.css'
      order:
        before: [
          'vendor/styles/normalize.css'
        ]
        after: [
          'vendor/styles/helpers.css'
          'vendor/styles/jquery.mobile-1.3.1.min.css'
          'vendor/styles/jquery.mobile.theme-1.3.1.min.css'
          # 'vendor/styles/jquery-ui-1.10.3.custom.min.css'
          'vendor/styles/flashblock.css'
        ]
    templates:
      defaultExtension: 'eco'
      joinTo: 'javascripts/app.js'
  minify: no
