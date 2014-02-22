(function(/*! Brunch !*/) {
  'use strict';

  var globals = typeof window !== 'undefined' ? window : global;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\.\.?(\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    definition(module.exports, localRequire(name), module);
    var exports = cache[name] = module.exports;
    return exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path];
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex];
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  var list = function() {
    var result = [];
    for (var item in modules) {
      if (has(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  globals.require = require;
  globals.require.define = define;
  globals.require.register = define;
  globals.require.list = list;
  globals.require.brunch = true;
})();
require.register("appcache", function(exports, require, module) {
var AppCacheHandler, AppCacheStatus;

AppCacheStatus = require('views/templates/app_cache_status');

module.exports = AppCacheHandler = function() {
  var counter, fadeOutLoader, incrementLoadingCount, loadingFloat, updateLoadingCount, updateLoadingStatusMessage,
    _this = this;
  console.log("Initializing appCache");
  loadingFloat = function() {
    var loading;
    if ($('#loading_float').length === 0) {
      loading = AppCacheStatus({
        obj_count: 55
      });
      $('body').append(loading);
      loading = $('#loading_float');
    } else {
      loading = $('#loading_float');
    }
    loading.fadeOut(4500);
    return loading;
  };
  updateLoadingCount = function(count, total) {
    var loader, _count, _total;
    loader = loadingFloat();
    loader.fadeIn(500);
    _count = loader.find('#cache_count');
    _total = loader.find('#cache_total');
    _count.html(count);
    _total.html(total);
    return true;
  };
  incrementLoadingCount = function() {
    var count, loader, total, _count, _total;
    loader = loadingFloat();
    _count = loader.find('#cache_count');
    _total = loader.find('#cache_total');
    count = parseInt(loader.find('#cache_count').html());
    total = parseInt(loader.find('#cache_total').html());
    if (isNaN(count) || isNaN(total)) {
      count = 0;
      total = 0;
    }
    return updateLoadingCount(count + 1, total);
  };
  updateLoadingStatusMessage = function(msg) {
    var loader, _msg;
    loader = loadingFloat();
    loader.fadeIn(500);
    _msg = loader.find('#status #message');
    _msg.html(msg);
    return true;
  };
  fadeOutLoader = function() {
    var loader;
    loader = loadingFloat().fadeOut(1500);
    return true;
  };
  window.updateLoadingCount = updateLoadingCount;
  window.incrementLoadingCount = incrementLoadingCount;
  window.updateLoadingStatusMessage = updateLoadingStatusMessage;
  window.fadeOutLoader = fadeOutLoader;
  loadingFloat();
  if (window.applicationCache) {
    window.applicationCache.onchecking = function(e) {
      console.log("onchecking");
      return updateLoadingStatusMessage("Checking for new media files.");
    };
    window.applicationCache.onnoupdate = function(e) {
      console.log("No updates");
      updateLoadingStatusMessage("No updates.");
      return fadeOutLoader();
    };
    window.applicationCache.onupdateready = function(e) {
      console.log("Update ready");
      updateLoadingStatusMessage("Update finished.");
      return fadeOutLoader();
    };
    window.applicationCache.onobsolete = function(e) {
      return console.log("Obsolete");
    };
    window.applicationCache.ondownloading = function(e) {
      console.log("Downloading");
      return updateLoadingStatusMessage("Downloading ...");
    };
    window.applicationCache.oncached = function(e) {
      console.log("Cached");
      updateLoadingStatusMessage("Offline files downloaded.");
      return fadeOutLoader();
    };
    window.applicationCache.onerror = function(e) {
      console.log("Error");
      return updateLoadingStatusMessage("Caching error! Error connecting.");
    };
    counter = 0;
    window.applicationCache.onprogress = function(e) {
      console.log("checking");
      console.log("Progress: downloaded file " + counter);
      incrementLoadingCount();
      return counter++;
    };
    window.addEventListener("online", function(e) {
      return console.log("you are online");
    });
    return window.addEventListener("offline", function(e) {
      return console.log("you are offline");
    });
  } else {
    return fadeOutLoader();
  }
};
});

;require.register("application", function(exports, require, module) {
var Application, AudioPlayer, Authenticator, CategoryList, ConceptDB, LeksaOptions, LoadingTracker, QuestionDB, Router, Tests, UserProgression, UserSettings, arrayChunk, makeLogger;

Router = require('routers/router');

Authenticator = require('auth/authentication');

UserSettings = require('models/user_settings');

UserProgression = require('models/user_progression');

LoadingTracker = require('loadingtracker');

ConceptDB = require('models/conceptdb');

CategoryList = require('models/categorylist');

QuestionDB = require('models/questiondb');

AudioPlayer = require('media/audio_player');

Tests = require('tests/tests');

require('backbone.offline');

require('language_codes');

window.initWindowCache = require('appcache');

arrayChunk = function(a, s) {
  var c, i, l, n, x;
  x = void 0;
  i = 0;
  c = -1;
  l = a.length;
  n = [];
  while (i < l) {
    if ((x = i % s)) {
      n[c][x] = a[i];
    } else {
      n[++c] = [a[i]];
    }
    i++;
  }
  return n;
};

window.arrayChunk = arrayChunk;

Function.prototype.bind = function(parent) {
  var a, args, f, temp;
  f = this;
  args = [];
  a = 1;
  while (a < args.length) {
    args[args.length] = args[a];
    a++;
  }
  temp = function() {
    return f.apply(parent, args);
  };
  return temp;
};

LeksaOptions = (function() {
  function LeksaOptions() {}

  return LeksaOptions;

})();

module.exports = Application = (function() {
  var _this = this;

  Application.prototype.enable_webfonts = function() {
    if (typeof WebFont === "undefined" || WebFont === null) {
      console.log("ERROR: WebFont async loader not available.");
      return;
    }
    return WebFont.load({
      google: {
        families: ['Open Sans', 'Kaushan Script']
      }
    });
  };

  Application.prototype.switch_locale = function(locale, options) {
    var conv_l,
      _this = this;
    if (options == null) {
      options = {};
    }
    conv_l = ISOs.three_to_two(locale);
    if (conv_l !== locale) {
      locale = conv_l;
    }
    return $.get(app.server.path + ("/data/translations/" + locale + "/messages.json"), function(locale_data) {
      var gettext;
      gettext = new Gettext({
        domain: 'messages',
        locale_data: locale_data
      });
      _this.gettext = gettext;
      window.gettext = _this.gettext;
      _this.loadingTracker.markReady('translations.json');
      if (options.complete) {
        return options.complete();
      }
    });
  };

  Application.prototype.soundEffectCorrect = function() {
    this.correct_concept = _.first(this.conceptdb.where({
      semantics: ["CORRECT"],
      concept_value: "CORRECT"
    }));
    if (this.correct_concept) {
      this.correct_concept.playAudio();
    }
    return true;
  };

  Application.prototype.soundEffectIncorrect = function() {
    this.incorrect_concept = _.first(this.conceptdb.where({
      semantics: ["INCORRECT"],
      concept_value: "INCORRECT"
    }));
    if (this.incorrect_concept) {
      this.incorrect_concept.playAudio();
    }
    return true;
  };

  Application.prototype.soundEffects = {
    'click': function() {
      return app.audio.playPath('/static/audio/click.mp3');
    },
    'correct': function() {
      return app.soundEffectCorrect();
    },
    'incorrect': function() {
      return app.soundEffectIncorrect();
    }
  };

  function Application() {
    var _this = this;
    $(function() {
      _this.enable_webfonts();
      return _this.initialize({
        complete: function() {
          var debug_watch;
          Backbone.history.start({
            pushState: false,
            hashChange: true,
            root: window.location.pathname
          });
          $(document).bind("pagechange", function(e, data) {
            var not_string, root_page, webkit;
            webkit = $.browser.webkit;
            not_string = data.toPage !== "string";
            root_page = data.toPage.attr("data-url") === '/';
            if (webkit && not_string && root_page) {
              app.router.index();
              return e.preventDefault();
            }
          });
          if (app.options.getSetting('enable_cache') != null) {
            initWindowCache();
          }
          if (window.location.hostname === 'localhost') {
            console.log("Appending debug watcher");
            debug_watch = $("<script />");
            debug_watch.attr('src', "http://localhost:9001/ws");
            return debug_watch.appendTo('head');
          }
        }
      });
    });
  }

  Application.prototype.initialize = function(options) {
    var initial_language,
      _this = this;
    if (options == null) {
      options = {};
    }
    this.device_type = "mobile";
    this.media_size = "small";
    this.video_format = "gif";
    this.server = {
      path: "http://localhost:5000"
    };
    if ($(window).width() > 499) {
      this.device_type = "tablet";
      this.media_size = "medium";
    }
    this.screen_width = $(window).width();
    this.screen_height = $(window).height();
    this.loadingTracker = new LoadingTracker({
      'concepts.json': false,
      'leksa_questions.json': false,
      'translations.json': false,
      'categories.json': false
    });
    this.loadingTracker.showLoading();
    this.audio = new AudioPlayer();
    this.gettext = new Gettext({
      domain: 'messages'
    });
    window.gettext = this.gettext;
    this.auth = new Authenticator();
    this.tests = new Tests();
    this.conceptdb = new ConceptDB();
    this.conceptdb.fetch({
      success: function() {
        window.fetched_somewhere = true;
        app.loadingTracker.markReady('concepts.json');
        return console.log("fetched concepts.json (" + app.conceptdb.models.length + ")");
      }
    });
    this.categories = new CategoryList();
    this.categories.fetch({
      success: function() {
        window.fetched_somewhere = true;
        app.loadingTracker.markReady('categories.json');
        return console.log("fetched categories.json (" + app.conceptdb.models.length + ")");
      }
    });
    this.questiondb = new QuestionDB();
    this.userprogression = new UserProgression();
    this.leksaOptions = new LeksaOptions();
    this.router = new Router();
    soundManager.setup({
      url: "/static/client/swf/",
      debugMode: false,
      defaultOptions: {
        volume: 50
      },
      useConsole: true,
      preferFlash: false,
      useHTML5Audio: true,
      useFlashBlock: true,
      onready: function() {
        return console.log("SoundManager ready");
      },
      ontimeout: function() {
        return window.client_log.error('SM2 init failed!');
      }
    });
    initial_language = navigator.language || navigator.userLanguage || "no";
    if (initial_language !== "sma" && initial_language !== "sv" && initial_language !== "no") {
      initial_language = "no";
    }
    initial_language = ISOs.three_to_two(initial_language);
    this.switch_locale(initial_language, options);
    this.options = new UserSettings();
    return this.options.setSettings({
      'interface_language': ISOs.two_to_three(initial_language),
      'help_language': ISOs.two_to_three(initial_language)
    });
  };

  return Application;

}).call(this);

makeLogger = function() {
  var ajaxlogger, log;
  log = log4javascript.getLogger();
  ajaxlogger = new log4javascript.AjaxAppender('/client_logger/');
  log.addAppender(ajaxlogger);
  return log;
};

window.app = new Application;

window.client_log = makeLogger();

window.onerror = function(errorMsg, url, lineNumber) {
  return window.client_log.fatal("Uncaught error " + errorMsg + " in " + url + ", line " + lineNumber);
};
});

;require.register("auth/authentication", function(exports, require, module) {
var Authenticator, LoginTemplate;

LoginTemplate = require('/views/users/templates/login_modal');

module.exports = Authenticator = (function() {
  function Authenticator() {}

  Authenticator.prototype.hide_authentication_popup = function(el) {
    return el.find('#loginPopup').hide();
  };

  Authenticator.prototype.render_authentication_popup = function(el, opts) {
    var auth_popup_form_submit, login_template, popup, resetState,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    auth_popup_form_submit = function(event) {
      if (app.debug) {
        console.log("Authenticator.login: submitted");
      }
      el.find('#loginPopup #loading').fadeIn();
      _this.login({
        username: el.find('#loginPopup #un').val(),
        password: el.find('#loginPopup #pw').val(),
        success: function(data, textStatus, jqXHR) {
          el.find('#loginPopup #loading').fadeOut();
          el.find('#loginPopup #success').fadeIn();
          if (opts.success) {
            return opts.success(data, textStatus, jqXHR);
          }
        },
        fail: function(resp) {
          el.find('#loginPopup #loading').fadeOut();
          el.find('#loginPopup #fail').fadeIn();
          el.find('#loginPopup #login_error').html(resp.error);
          if (opts.fail) {
            return opts.fail();
          }
        }
      });
      return false;
    };
    resetState = function() {
      el.find('#loginPopup #loading').hide();
      el.find('#loginPopup #success').hide();
      el.find('#loginPopup #fail').hide();
      return el.find('#loginPopup #pw').val('');
    };
    if ($('#loginPopup').length === 0) {
      login_template = LoginTemplate();
      el.append(login_template);
      el.find('#loginPopup').trigger('create');
      el.find('#loginPopup form').submit(auth_popup_form_submit);
      el.find('#loginPopup .close_modal').click(function(e) {
        var popup;
        popup = el.find("#loginPopup");
        return popup.popup().hide().popup('close');
      });
    }
    popup = el.find("#loginPopup");
    resetState();
    popup.popup().show().popup('open');
    return false;
  };

  Authenticator.prototype.create_user = function(opts) {
    var data, _create_user,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    data = {
      username: opts.username,
      email: opts.email,
      password: opts.password
    };
    _create_user = $.post("/user/create/", data);
    _create_user.fail(function(response) {
      if (app.debug) {
        console.log("auth.create_user: fail");
      }
      if (opts.fail) {
        return opts.fail(response);
      }
    });
    _create_user.success(function(response) {
      if (app.debug) {
        console.log("auth.create_user: success");
      }
      if (opts.success) {
        return opts.success(response);
      }
    });
    _create_user.always(function(response) {
      if (app.debug) {
        console.log("auth.create_user: always");
      }
      if (opts.always) {
        return opts.always(response);
      }
    });
    return opts;
  };

  Authenticator.prototype.logout = function(opts) {
    var logout_request,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    logout_request = $.ajax({
      type: "GET",
      url: "/user/logout/",
      xhrFields: {
        withCredentials: true
      }
    });
    logout_request.fail(function(resp) {
      console.log("Authenticator.logout.logout_request.fail: fail");
      console.log(JSON.parse(resp.responseText));
      app.user = null;
      if (opts.fail) {
        return opts.fail(resp);
      }
    });
    return logout_request.success(function(data, textStatus, jqXHR) {
      app.user = false;
      if (app.debug) {
        console.log("Authenticator.logout.logout_request.success");
      }
      _this.clearUserData();
      if (opts.success) {
        return opts.success(data, textStatus, jqXHR);
      }
    });
  };

  Authenticator.prototype.clearUserData = function() {
    var deets;
    if (app.debug) {
      console.log("Authenticator.clearUserData()");
    }
    deets = DSt.get('login-details');
    window.localStorage.clear();
    app.options.reset();
    app.userprogression.reset();
    deets = DSt.set('login-details', deets);
    if (app.debug) {
      console.log("Cleared user data.");
      return console.log([app.userprogression.length, app.options.length, window.localStorage]);
    }
  };

  Authenticator.prototype.forgot = function(opts) {
    var data, forgotten_request,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    data = {};
    if (opts.email) {
      data.email_address = opts.email;
    }
    if (opts.username) {
      data.username = opts.username;
    }
    forgotten_request = $.ajax({
      type: "POST",
      url: "/user/forgot/",
      data: data,
      xhrFields: {
        withCredentials: true
      }
    });
    forgotten_request.fail(function(resp) {
      console.log("fail");
      console.log(JSON.parse(resp.responseText));
      app.user = null;
      if (opts.fail) {
        return opts.fail(resp);
      }
    });
    forgotten_request.success(function(data, textStatus, jqXHR) {
      if (app.debug) {
        console.log("Authenticator.login.forgot: Request for token successfully submitted ...");
      }
      if (opts.success) {
        return opts.success();
      }
    });
    return forgotten_request.complete(function() {
      if (opts.complete) {
        return opts.complete();
      }
    });
  };

  Authenticator.prototype.login = function(opts) {
    var data, login_request,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    data = {
      username: opts.username,
      password: opts.password
    };
    login_request = $.ajax({
      type: "POST",
      url: "/user/login/",
      data: data,
      xhrFields: {
        withCredentials: true
      }
    });
    login_request.fail(function(resp) {
      console.log("fail");
      console.log(JSON.parse(resp.responseText));
      app.user = null;
      if (opts.fail) {
        return opts.fail(resp);
      }
    });
    login_request.success(function(data, textStatus, jqXHR) {
      var test_authed_request;
      if (app.debug) {
        console.log("Authenticator.login.success: Should be logged in...");
      }
      test_authed_request = $.getJSON('/user/data/log');
      test_authed_request.success(function(resp) {
        if (app.debug) {
          console.log("Authenticator.login.success.tesst_authed_request: ");
          return console.log(resp);
        }
      });
      app.user = {
        username: data.user.username,
        email: data.user.email
      };
      if (opts.success) {
        return opts.success();
      }
    });
    return login_request.complete(function() {
      if (app.debug) {
        console.log("User logged in, syncing progression");
      }
      return $.when(app.userprogression.storage.sync.full({
        success: function(data) {
          if (app.debug) {
            return console.log("userlog.full.success");
          }
        }
      }), app.options.storage.sync.full({
        success: function(data) {
          if (app.debug) {
            return console.log("storage.full.success");
          }
        }
      })).then(function() {
        if (app.debug) {
          console.log("all login requests complete");
        }
        if (opts.success) {
          return opts.success();
        }
      });
    });
  };

  return Authenticator;

})();
});

;require.register("backbone.offline", function(exports, require, module) {
(function(global, _, Backbone) {
  global.Offline = {
    VERSION: '0.4.3a',
    localSync: function(method, model, options, store) {
      var resp, _ref;
      resp = (function() {
        switch (method) {
          case 'read':
            if (_.isUndefined(model.id)) {
              return store.findAll(options);
            } else {
              return store.find(model, options);
            }
            break;
          case 'create':
            return store.create(model, options);
          case 'update':
            return store.update(model, options);
          case 'delete':
            return store.destroy(model, options);
        }
      })();
      if (resp) {
        return options.success((_ref = resp.attributes) != null ? _ref : resp);
      } else {
        return typeof options.error === "function" ? options.error('Record not found') : void 0;
      }
    },
    sync: function(method, model, options) {
      var store, _ref;
      store = model.storage || ((_ref = model.collection) != null ? _ref.storage : void 0);
      if (store && (store != null ? store.support : void 0)) {
        return Offline.localSync(method, model, options, store);
      } else {
        return Backbone.ajaxSync(method, model, options);
      }
    },
    onLine: function() {
      return navigator.onLine !== false;
    }
  };
  Backbone.ajaxSync = Backbone.sync;
  Backbone.sync = Offline.sync;
  Offline.Storage = (function() {
    function Storage(name, collection, options) {
      this.name = name;
      this.collection = collection;
      if (options == null) {
        options = {};
      }
      this.support = this.isLocalStorageSupport();
      this.allIds = new Offline.Index(this.name, this);
      this.destroyIds = new Offline.Index("" + this.name + "-destroy", this);
      this.sync = new Offline.Sync(this.collection, this);
      this.keys = options.keys || {};
      this.autoPush = options.autoPush || false;
    }

    Storage.prototype.isLocalStorageSupport = function() {
      var e;
      try {
        localStorage.setItem('isLocalStorageSupport', '1');
        localStorage.removeItem('isLocalStorageSupport');
        return true;
      } catch (_error) {
        e = _error;
        return false;
      }
    };

    Storage.prototype.setItem = function(key, value) {
      var e;
      try {
        return localStorage.setItem(key, value);
      } catch (_error) {
        e = _error;
        if (e.name === 'QUOTA_EXCEEDED_ERR') {
          return this.collection.trigger('quota_exceed');
        } else {
          return this.support = false;
        }
      }
    };

    Storage.prototype.removeItem = function(key) {
      return localStorage.removeItem(key);
    };

    Storage.prototype.getItem = function(key) {
      return localStorage.getItem(key);
    };

    Storage.prototype.create = function(model, options) {
      if (options == null) {
        options = {};
      }
      options.regenerateId = true;
      return this.save(model, options);
    };

    Storage.prototype.update = function(model, options) {
      if (options == null) {
        options = {};
      }
      return this.save(model, options);
    };

    Storage.prototype.destroy = function(model, options) {
      var sid;
      if (options == null) {
        options = {};
      }
      if (!(options.local || (sid = model.get('sid')) === 'new')) {
        this.destroyIds.add(sid);
      }
      return this.remove(model, options);
    };

    Storage.prototype.find = function(model, options) {
      if (options == null) {
        options = {};
      }
      return JSON.parse(this.getItem("" + this.name + "-" + model.id));
    };

    Storage.prototype.findAll = function(options) {
      var id, _i, _len, _ref, _results;
      if (options == null) {
        options = {};
      }
      if (!options.local) {
        if (this.isEmpty()) {
          this.sync.full(options);
        } else {
          this.sync.incremental(options);
        }
      }
      _ref = this.allIds.values;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        id = _ref[_i];
        _results.push(JSON.parse(this.getItem("" + this.name + "-" + id)));
      }
      return _results;
    };

    Storage.prototype.s4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };

    Storage.prototype.incrementId = 0x1000000;

    Storage.prototype.localId1 = ((1 + Math.random()) * 0x100000 | 0).toString(16).substring(1);

    Storage.prototype.localId2 = ((1 + Math.random()) * 0x100000 | 0).toString(16).substring(1);

    Storage.prototype.mid = function() {
      return ((new Date).getTime() / 1000 | 0).toString(16) + this.localId1 + this.localId2 + (++this.incrementId).toString(16).substring(1);
    };

    Storage.prototype.guid = function() {
      return this.s4() + this.s4() + '-' + this.s4() + '-' + this.s4() + '-' + this.s4() + '-' + this.s4() + this.s4() + this.s4();
    };

    Storage.prototype.save = function(item, options) {
      var id, _ref, _ref1;
      if (options == null) {
        options = {};
      }
      if (options.regenerateId) {
        id = options.id === 'mid' ? this.mid() : this.guid();
        item.set({
          sid: ((_ref = item.attributes) != null ? _ref.sid : void 0) || ((_ref1 = item.attributes) != null ? _ref1.id : void 0) || 'new',
          id: id
        });
      }
      if (!options.local) {
        item.set({
          updated_at: (new Date()).toJSON(),
          dirty: true
        });
      }
      this.replaceKeyFields(item, 'local');
      this.setItem("" + this.name + "-" + item.id, JSON.stringify(item));
      this.allIds.add(item.id);
      if (this.autoPush && !options.local) {
        this.sync.pushItem(item);
      }
      return item;
    };

    Storage.prototype.remove = function(item, options) {
      var sid;
      if (options == null) {
        options = {};
      }
      this.removeItem("" + this.name + "-" + item.id);
      this.allIds.remove(item.id);
      sid = item.get('sid');
      if (this.autoPush && sid !== 'new' && !options.local) {
        this.sync.flushItem(sid);
      }
      return item;
    };

    Storage.prototype.isEmpty = function() {
      return this.getItem(this.name) === null;
    };

    Storage.prototype.clear = function() {
      var collectionKeys, key, keys, record, _i, _j, _len, _len1, _ref, _results,
        _this = this;
      keys = Object.keys(localStorage);
      collectionKeys = _.filter(keys, function(key) {
        return (new RegExp(_this.name)).test(key);
      });
      for (_i = 0, _len = collectionKeys.length; _i < _len; _i++) {
        key = collectionKeys[_i];
        this.removeItem(key);
      }
      _ref = [this.allIds, this.destroyIds];
      _results = [];
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        record = _ref[_j];
        _results.push(record.reset());
      }
      return _results;
    };

    Storage.prototype.replaceKeyFields = function(item, method) {
      var collection, field, newValue, replacedField, wrapper, _ref, _ref1, _ref2;
      if (Offline.onLine()) {
        if (item.attributes) {
          item = item.attributes;
        }
        _ref = this.keys;
        for (field in _ref) {
          collection = _ref[field];
          replacedField = item[field];
          if (!/^\w{8}-\w{4}-\w{4}/.test(replacedField) || method !== 'local') {
            newValue = method === 'local' ? (wrapper = new Offline.Collection(collection), (_ref1 = wrapper.get(replacedField)) != null ? _ref1.id : void 0) : (_ref2 = collection.get(replacedField)) != null ? _ref2.get('sid') : void 0;
            if (!_.isUndefined(newValue)) {
              item[field] = newValue;
            }
          }
        }
      }
      return item;
    };

    return Storage;

  })();
  Offline.Sync = (function() {
    function Sync(collection, storage) {
      this.collection = new Offline.Collection(collection);
      this.storage = storage;
    }

    Sync.prototype.ajax = function(method, model, options) {
      if (Offline.onLine()) {
        this.prepareOptions(options);
        return Backbone.ajaxSync(method, model, options);
      } else {
        return this.storage.setItem('offline', 'true');
      }
    };

    Sync.prototype.full = function(options) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      return this.ajax('read', this.collection.items, _.extend({}, options, {
        success: function(response) {
          var item, _i, _len;
          if (_this.storage.collection.parse) {
            response = _this.storage.collection.parse(response);
          }
          _this.storage.clear();
          _this.collection.items.reset([], {
            silent: true
          });
          for (_i = 0, _len = response.length; _i < _len; _i++) {
            item = response[_i];
            _this.collection.items.create(item, {
              silent: true,
              local: true,
              regenerateId: true
            });
          }
          if (!options.silent) {
            _this.collection.items.trigger('reset');
          }
          if (options.success) {
            return options.success(response);
          }
        }
      }));
    };

    Sync.prototype.incremental = function(options) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      return this.pull(_.extend({}, options, {
        success: function() {
          return _this.push();
        }
      }));
    };

    Sync.prototype.prepareOptions = function(options) {
      var success,
        _this = this;
      if (this.storage.getItem('offline')) {
        this.storage.removeItem('offline');
        success = options.success;
        return options.success = function(response) {
          success(response);
          return _this.incremental();
        };
      }
    };

    Sync.prototype.pull = function(options) {
      var _this = this;
      if (options == null) {
        options = {};
      }
      return this.ajax('read', this.collection.items, _.extend({}, options, {
        success: function(response) {
          var item, _i, _len;
          if (_this.storage.collection.parse) {
            response = _this.storage.collection.parse(response);
          }
          _this.collection.destroyDiff(response);
          for (_i = 0, _len = response.length; _i < _len; _i++) {
            item = response[_i];
            _this.pullItem(item);
          }
          if (options.success) {
            return options.success(response);
          }
        }
      }));
    };

    Sync.prototype.pullItem = function(item) {
      var local;
      local = this.collection.get(item.id);
      if (local) {
        return this.updateItem(item, local);
      } else {
        return this.createItem(item);
      }
    };

    Sync.prototype.createItem = function(item) {
      if (!_.include(this.storage.destroyIds.values, item.id.toString())) {
        item.sid = item.id;
        delete item.id;
        return this.collection.items.create(item, {
          local: true
        });
      }
    };

    Sync.prototype.updateItem = function(item, model) {
      if ((new Date(model.get('updated_at'))) < (new Date(item.updated_at))) {
        delete item.id;
        return model.save(item, {
          local: true
        });
      }
    };

    Sync.prototype.push = function() {
      var item, sid, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = this.collection.dirty();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        this.pushItem(item);
      }
      _ref1 = this.storage.destroyIds.values;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        sid = _ref1[_j];
        _results.push(this.flushItem(sid));
      }
      return _results;
    };

    Sync.prototype.pushItem = function(item) {
      var localId, method, _ref,
        _this = this;
      this.storage.replaceKeyFields(item, 'server');
      localId = item.id;
      delete item.attributes.id;
      _ref = item.get('sid') === 'new' ? ['create', null] : ['update', item.attributes.sid], method = _ref[0], item.id = _ref[1];
      this.ajax(method, item, {
        success: function(response) {
          if (method === 'create') {
            item.set({
              sid: response.id
            });
          }
          return item.save({
            dirty: false
          }, {
            local: true
          });
        }
      });
      item.attributes.id = localId;
      return item.id = localId;
    };

    Sync.prototype.flushItem = function(sid) {
      var model,
        _this = this;
      model = this.collection.fakeModel(sid);
      return this.ajax('delete', model, {
        success: function(model, response, opts) {
          return _this.storage.destroyIds.remove(sid);
        }
      });
    };

    return Sync;

  })();
  Offline.Index = (function() {
    function Index(name, storage) {
      var store;
      this.name = name;
      this.storage = storage;
      store = this.storage.getItem(this.name);
      this.values = (store && store.split(',')) || [];
    }

    Index.prototype.add = function(itemId) {
      if (!_.include(this.values, itemId.toString())) {
        this.values.push(itemId.toString());
      }
      return this.save();
    };

    Index.prototype.remove = function(itemId) {
      this.values = _.without(this.values, itemId.toString());
      return this.save();
    };

    Index.prototype.save = function() {
      return this.storage.setItem(this.name, this.values.join(','));
    };

    Index.prototype.reset = function() {
      this.values = [];
      return this.storage.removeItem(this.name);
    };

    return Index;

  })();
  return Offline.Collection = (function() {
    function Collection(items) {
      this.items = items;
    }

    Collection.prototype.dirty = function() {
      return this.items.where({
        dirty: true
      });
    };

    Collection.prototype.get = function(sid) {
      return this.items.find(function(item) {
        return item.get('sid') === sid;
      });
    };

    Collection.prototype.destroyDiff = function(response) {
      var diff, sid, _i, _len, _ref, _results;
      diff = _.difference(_.without(this.items.pluck('sid'), 'new'), _.pluck(response, 'id'));
      _results = [];
      for (_i = 0, _len = diff.length; _i < _len; _i++) {
        sid = diff[_i];
        _results.push((_ref = this.get(sid)) != null ? _ref.destroy({
          local: true
        }) : void 0);
      }
      return _results;
    };

    Collection.prototype.fakeModel = function(sid) {
      var model;
      model = new Backbone.Model({
        id: sid
      });
      model.urlRoot = this.items.url;
      return model;
    };

    return Collection;

  })();
})(window, _, Backbone);
});

;require.register("language_codes", function(exports, require, module) {
(function(global, _, Backbone) {
  var ISOConv;
  ISOConv = (function() {
    ISOConv.prototype.VERSION = '0.0.1';

    function ISOConv() {
      var k, v, _ref;
      _ref = this.ISOs;
      for (k in _ref) {
        v = _ref[k];
        if (this.reverseISOs[v] == null) {
          this.reverseISOs[v] = k;
        }
      }
    }

    ISOConv.prototype.reverseISOs = {
      "nob": "no"
    };

    ISOConv.prototype.ISOs = {
      "no": "nob",
      "nb": "nob",
      "nn": "nno",
      "sv": "swe",
      "fi": "fin",
      "en": "eng"
    };

    ISOConv.prototype.two_to_three = function(two) {
      if (this.ISOs[two] != null) {
        return this.ISOs[two];
      } else {
        return two;
      }
    };

    ISOConv.prototype.three_to_two = function(three) {
      if (this.reverseISOs[three] != null) {
        return this.reverseISOs[three];
      } else {
        return three;
      }
    };

    return ISOConv;

  })();
  return global.ISOs = new ISOConv();
})(window, _, Backbone);
});

;require.register("loadingtracker", function(exports, require, module) {
var LoadingDepsFailed, LoadingTracker,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

LoadingDepsFailed = (function(_super) {
  __extends(LoadingDepsFailed, _super);

  function LoadingDepsFailed() {
    var params;
    params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.params = params;
    LoadingDepsFailed.__super__.constructor.apply(this, arguments);
  }

  return LoadingDepsFailed;

})(Error);

module.exports = LoadingTracker = (function() {
  LoadingTracker.prototype.isReady = function() {
    var name, status, _ref;
    _ref = this.dependencies;
    for (name in _ref) {
      status = _ref[name];
      if (!status) {
        return false;
      }
    }
    console.log("In readiness.");
    return true;
  };

  LoadingTracker.prototype.waitForDeps = function(opts) {
    var _this = this;
    if (opts == null) {
      opts = {};
    }
    if (this.isReady()) {
      if (opts.ready != null) {
        return opts.ready();
      } else {
        return true;
      }
    } else {
      this.showLoading();
    }
    return this.check_handler = setInterval(function() {
      if (_this.isReady()) {
        if (opts.extra_test != null) {
          if (!opts.extra_test()) {
            return false;
          }
        }
        clearInterval(_this.check_handler);
        _this.hideLoading();
        if (opts.ready != null) {
          return opts.ready();
        } else {
          return false;
        }
      }
      if (opts.timeout != null) {
        if (total_wait > opts.timeout) {
          clearInterval(_this.check_handler);
          _this.hideLoading();
          if (opts.failed != null) {
            return opts.failed();
          } else {
            throw new LoadingDepsFailed();
          }
        }
      }
    }, 500);
  };

  LoadingTracker.prototype.checkDeps = function() {
    if (this.isReady()) {
      return this.hideLoading();
    }
  };

  LoadingTracker.prototype.markReady = function(name) {
    this.dependencies[name] = true;
    return this.checkDeps();
  };

  LoadingTracker.prototype.hideLoading = function() {
    var interval;
    interval = setInterval(function() {
      $.mobile.loading('hide');
      return clearInterval(interval);
    }, 1);
    return false;
  };

  LoadingTracker.prototype.showLoading = function() {
    var interval;
    interval = setInterval(function() {
      $.mobile.loading('show', {
        text: 'Loading...',
        textVisible: true,
        theme: 'a',
        html: ""
      });
      return clearInterval(interval);
    }, 1);
    return false;
  };

  function LoadingTracker(deps) {
    this.dependencies = deps;
  }

  return LoadingTracker;

})();
});

;require.register("media/audio_player", function(exports, require, module) {
var AudioPlayer, SoundLoadingTemplate;

SoundLoadingTemplate = require('../views/templates/sound_loading');

module.exports = AudioPlayer = (function() {
  function AudioPlayer() {}

  AudioPlayer.prototype.playPath = function(path, opts) {
    var begin_event, error_event, finished_event, loading, s, sound_id, sound_obj, whileload_event,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    loading = $(document).find('#sound_loading_bar');
    if (loading.length === 0) {
      $('body').append(SoundLoadingTemplate);
      loading = $('body').find('#sound_loading_bar');
    }
    error_event = function() {
      console.log("Audio playing error");
      return false;
    };
    finished_event = function() {
      loading.fadeOut();
      if (opts.finished != null) {
        opts.finished();
      }
      return false;
    };
    begin_event = function() {
      loading.fadeOut();
      if (opts.begin != null) {
        opts.begin();
      }
      return false;
    };
    whileload_event = function() {
      if (this.bytesTotal >= this.bytesLoaded) {
        if (loading.css('display') === 'none') {
          loading.fadeIn();
        }
      }
      if (this.bytesTotal === this.bytesLoaded) {
        return loading.fadeOut();
      }
    };
    if (soundManager.enabled) {
      sound_id = "concept_audio";
      if (soundManager.html5Only) {
        if (app.debug) {
          console.log("html5 only");
        }
        sound_obj = soundManager.getSoundById(sound_id);
        if (!sound_obj) {
          if (app.debug) {
            console.log("creating sound obj");
          }
          sound_obj = soundManager.createSound({
            id: sound_id,
            url: path,
            onfinish: finished_event,
            onerror: error_event,
            onplay: begin_event,
            whileloading: whileload_event
          });
          sound_obj._a.playbackRate = opts.rate;
        } else {
          if (app.debug) {
            console.log("sound obj exists");
          }
          sound_obj.options.onfinish = finished_event;
          sound_obj.options.onerror = error_event;
          sound_obj.options.onplay = begin_event;
          sound_obj.options.whileloading = whileload_event;
        }
        if (sound_obj.url === path) {
          if (app.debug) {
            console.log("concept.playAudio: repeat");
          }
        } else {
          if (app.debug) {
            console.log("concept.playAudio: no repeat");
          }
          sound_obj.url = path;
          window.so = sound_obj;
        }
        sound_obj.play({
          position: 0
        });
      } else {
        if (app.debug) {
          console.log("creating sound with flash");
        }
        soundManager.destroySound(sound_id);
        s = soundManager.createSound({
          id: sound_id,
          url: path,
          onfinish: finished_event,
          onerror: error_event,
          onplay: begin_event,
          whileloading: whileload_event
        });
        s.play({
          position: 0
        });
      }
      return s;
    }
    if (opts.finished) {
      return opts.finished();
    } else {
      return false;
    }
  };

  return AudioPlayer;

})();
});

;require.register("models/category", function(exports, require, module) {
var Category, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Category = (function(_super) {
  __extends(Category, _super);

  function Category() {
    _ref = Category.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Category.prototype.idAttribute = "c_id";

  Category.prototype.defaults = {
    children: [],
    activities: []
  };

  Category.prototype.initialize = function() {};

  Category.prototype.getConcepts = function(args) {
    var concepts, query, sorted, sorter, _order,
      _this = this;
    if (args == null) {
      args = {};
    }
    query = _.extend({
      semantics: this.get('semantics')
    }, args);
    concepts = app.conceptdb.where(query);
    if (this.attributes.order_by != null) {
      _order = this.attributes.order_by;
      sorter = function(a) {
        var _a_attr, _a_ext, _a_ord;
        _a_attr = a.attributes || {};
        _a_ext = _a_attr.extra_attributes || {};
        _a_ord = _a_ext[_order];
        return _a_ord;
      };
    } else {
      sorter = function(c) {
        return c.get('concept_value');
      };
    }
    sorted = _.sortBy(concepts, sorter);
    return sorted;
  };

  Category.prototype.children = function() {
    var c, cs;
    cs = this.get('children');
    if (cs.length === 0) {
      return false;
    } else {
      return (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = cs.length; _i < _len; _i++) {
          c = cs[_i];
          _results.push(new Category(c));
        }
        return _results;
      })();
    }
  };

  Category.prototype.hasThumbnail = function(opts) {
    var device, has_media, images_for_device, size;
    if (opts == null) {
      opts = {};
    }
    if (!opts.device) {
      device = app.device_type;
    } else {
      device = opts.device;
    }
    if (!opts.size) {
      size = app.media_size;
    } else {
      size = opts.size;
    }
    has_media = this.get('media');
    if (has_media == null) {
      return false;
    }
    if ('icon' in has_media) {
      if (has_media.icon.length > 0) {
        images_for_device = _.filter(has_media.icon, function(i) {
          return i.size === size && i.device === device;
        });
        if (images_for_device.length === 0) {
          return has_media.icon[0].path;
        }
        if (images_for_device.length > 0) {
          return images_for_device[0].path;
        }
        return images_for_device;
      }
    }
    return false;
  };

  Category.prototype.hasImage = function(opts) {
    var device, has_media, images_for_device, size;
    if (opts == null) {
      opts = {};
    }
    if (!opts.device) {
      device = app.device_type;
    } else {
      device = opts.device;
    }
    if (!opts.size) {
      size = app.media_size;
    } else {
      size = opts.size;
    }
    has_media = this.get('media');
    if (has_media == null) {
      return false;
    }
    if ('image' in has_media) {
      if (has_media.image.length > 0) {
        images_for_device = _.filter(has_media.image, function(i) {
          return i.size === size && i.device === device;
        });
        if (images_for_device.length === 0) {
          return has_media.image[0].path;
        }
        if (images_for_device.length > 0) {
          return images_for_device[0].path;
        }
        return images_for_device;
      }
    }
    return false;
  };

  return Category;

})(Backbone.Model);
});

;require.register("models/categorylist", function(exports, require, module) {
var Category, CategoryList, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Category = require('models/category');

module.exports = CategoryList = (function(_super) {
  __extends(CategoryList, _super);

  function CategoryList() {
    _ref = CategoryList.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  CategoryList.prototype.model = Category;

  CategoryList.prototype.url = function() {
    return app.server.path + "/data/categories.json";
  };

  CategoryList.prototype.parse = function(response, opts) {
    return response.categories;
  };

  CategoryList.prototype.initialize = function() {};

  return CategoryList;

})(Backbone.Collection);
});

;require.register("models/collection", function(exports, require, module) {
var Collection, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Collection = (function(_super) {
  __extends(Collection, _super);

  function Collection() {
    _ref = Collection.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Collection.prototype.model = require('./model');

  return Collection;

})(Backbone.Collection);
});

;require.register("models/concept", function(exports, require, module) {
var Concept, LeksaConceptTemplate, SoundLoadingTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LeksaConceptTemplate = require('../views/templates/leksa_concept');

SoundLoadingTemplate = require('../views/templates/sound_loading');

module.exports = Concept = (function(_super) {
  __extends(Concept, _super);

  function Concept() {
    _ref = Concept.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Concept.prototype.idAttribute = "c_id";

  Concept.prototype.defaults = {
    fails: false,
    last_sound_path: ''
  };

  Concept.prototype.successRateInUserLog = function() {
    var correct_values, count_correct, log_entries_for_concept, total;
    log_entries_for_concept = app.userprogression.where({
      question_concept_value: this.get('concept_value')
    });
    correct_values = app.userprogression.where({
      question_concept_value: this.get('concept_value'),
      question_correct: true
    });
    total = log_entries_for_concept.length;
    count_correct = correct_values.length;
    if (total > 0) {
      return count_correct / total;
    } else {
      return false;
    }
  };

  Concept.prototype.hasThumbnail = function() {
    var has_media, thumbs;
    thumbs = false;
    has_media = this.get('media');
    if ('image' in has_media) {
      if (has_media.image.length > 0) {
        thumbs = _.filter(has_media.image, function(i) {
          return i.size === 'thumbnail';
        });
        if (thumbs.length === 0) {
          thumbs = false;
        }
      }
    }
    return thumbs;
  };

  Concept.prototype.hasVideo = function(opts) {
    var device, format, has_media, size, videos_for_device;
    if (opts == null) {
      opts = {};
    }
    if (!opts.device) {
      device = app.device_type;
    } else {
      device = opts.device;
    }
    if (!opts.size) {
      size = app.media_size;
    } else {
      size = opts.size;
    }
    if (!opts.format) {
      format = app.video_format;
    } else {
      format = opts.format;
    }
    has_media = this.get('media');
    if ('videos' in has_media) {
      if (has_media.videos.length > 0) {
        videos_for_device = _.filter(has_media.videos, function(i) {
          return i.size === size && i.device === device && i.format === format;
        });
        if (videos_for_device.length === 0) {
          return false;
        }
        if (videos_for_device.length > 0) {
          return videos_for_device[0];
        }
        return videos_for_device;
      }
    }
    if (opts.no_default) {
      return false;
    }
    return "/static/images/missing_concept_image.jpg";
  };

  Concept.prototype.hasGif = function(opts) {
    if (opts == null) {
      opts = {};
    }
  };

  Concept.prototype.hasImage = function(opts) {
    var device, gif, gifs, has_media, images_for_device, size;
    if (opts == null) {
      opts = {};
    }
    if (!opts.device) {
      device = app.device_type;
    } else {
      device = opts.device;
    }
    if (!opts.size) {
      size = app.media_size;
    } else {
      size = opts.size;
    }
    if (!opts.gif) {
      gif = false;
    } else {
      gif = true;
    }
    has_media = this.get('media');
    if ('image' in has_media) {
      if (has_media.image.length > 0) {
        images_for_device = _.filter(has_media.image, function(i) {
          return i.size === size && i.device === device;
        });
        if (gif) {
          gifs = _.filter(images_for_device, function(i) {
            return i.path.search('.gif') > -1;
          });
          if (gifs.length > 0) {
            return gifs[0].path;
          }
        } else {
          images_for_device = _.filter(images_for_device, function(i) {
            return i.path.search('.gif') === -1;
          });
        }
        if (images_for_device.length === 0) {
          return has_media.image[0].path;
        }
        if (images_for_device.length > 0) {
          return images_for_device[0].path;
        }
        return images_for_device;
      }
    }
    if (opts.no_default) {
      return false;
    }
    return "/static/images/missing_concept_image.jpg";
  };

  Concept.prototype.getTranslationsToLang = function(lang) {
    var _this = this;
    return this.getTranslations().filter(function(c) {
      return c.get('language') === lang;
    });
  };

  Concept.prototype.getTranslations = function() {
    var _this = this;
    return this.collection.filter(function(comp_concept) {
      if (_.contains(_this.get('translations'), comp_concept.get('c_id'))) {
        return true;
      } else {
        return false;
      }
    });
  };

  Concept.prototype.hasAudio = function() {
    var audios, has_audio_file, has_media, is_not_last_path,
      _this = this;
    has_media = this.get('media');
    is_not_last_path = function(s) {
      return s.path !== _this.last_sound_path;
    };
    if (app.options.getSetting('enable_audio') && (has_media.audio != null)) {
      if (has_media.audio.length > 0) {
        audios = has_media.audio;
        if (audios.length > 1) {
          audios = _.filter(has_media.audio, is_not_last_path);
        }
        has_audio_file = _.first(_.shuffle(audios)).path;
        if (audios.length > 1) {
          this.last_sound_path = has_audio_file;
        }
        return has_audio_file;
      }
    }
    return false;
  };

  Concept.prototype.playAudio = function(opts) {
    var has_audio_file;
    if (opts == null) {
      opts = {};
    }
    has_audio_file = this.hasAudio();
    if (has_audio_file) {
      return app.audio.playPath(has_audio_file, opts);
    }
  };

  Concept.prototype.render_concept = function() {
    var concept_media_value;
    concept_media_value = this.get('concept_value');
    if (this.get('concept_type') === 'img') {
      concept_media_value = this.hasImage();
    }
    return LeksaConceptTemplate({
      concept: this,
      concept_type: this.get('concept_type'),
      concept_value: concept_media_value
    });
  };

  return Concept;

})(Backbone.Model);
});

;require.register("models/conceptdb", function(exports, require, module) {
var Concept, ConceptDB, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Concept = require('models/concept');

module.exports = ConceptDB = (function(_super) {
  __extends(ConceptDB, _super);

  function ConceptDB() {
    _ref = ConceptDB.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  ConceptDB.prototype.model = Concept;

  ConceptDB.prototype.idAttribute = "c_id";

  ConceptDB.prototype.url = function() {
    return app.server.path + "/data/concepts.json";
  };

  ConceptDB.prototype.initialize = function() {};

  ConceptDB.prototype.getByCid = function(cid) {
    var ms,
      _this = this;
    ms = this.models.filter(function(m) {
      return m.cid === cid;
    });
    if (ms.length > 0) {
      return ms[0];
    } else {
      return false;
    }
  };

  ConceptDB.prototype.whereSemantics = function(sets, extra_filter) {
    var filtered, more_collection, more_filtered, result_collection, _type, _type_str,
      _this = this;
    _type = Object.prototype.toString.call(sets);
    _type_str = Object.prototype.toString.call("str");
    if (_type === _type_str) {
      sets = [sets];
    }
    filtered = this.models.filter(function(m) {
      var sem_match;
      sem_match = _.intersection(m.get('semantics'), sets);
      return sem_match.length > 0;
    });
    result_collection = new ConceptDB();
    result_collection.add(filtered);
    if (extra_filter) {
      more_filtered = result_collection.where(extra_filter);
      more_collection = new ConceptDB();
      more_collection.add(more_filtered);
      return more_collection;
    }
    return result_collection;
  };

  ConceptDB.prototype.titleImages = function(semantic_set) {
    var concepts, images;
    concepts = this.where({
      'semantics': [semantic_set]
    }).filter(function(concept) {
      return concept.hasThumbnail();
    });
    if (concepts.length > 0) {
      images = concepts[0].hasThumbnail();
      return images;
    }
    return false;
  };

  ConceptDB.prototype.where = function(params) {
    var new_coll;
    if ('semantics' in params) {
      new_coll = this.whereSemantics(params.semantics);
      delete params.semantics;
      if (Object.keys(params).length > 0) {
        return new_coll.where(params);
      } else {
        return new_coll.models;
      }
    }
    return ConceptDB.__super__.where.apply(this, arguments);
  };

  ConceptDB.prototype.getTranslationsOf = function(concept) {
    var _this = this;
    return this.models.filter(function(comp_concept) {
      if (_.contains(concept.get('translations'), comp_concept.get('id'))) {
        return true;
      } else {
        return false;
      }
    });
  };

  return ConceptDB;

})(Backbone.Collection);
});

;require.register("models/exceptions/level_complete", function(exports, require, module) {
var LevelComplete,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

module.exports = LevelComplete = (function(_super) {
  __extends(LevelComplete, _super);

  function LevelComplete() {
    var params;
    params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.params = params;
    LevelComplete.__super__.constructor.apply(this, arguments);
  }

  return LevelComplete;

})(Error);
});

;require.register("models/exceptions/progression_cycle_done", function(exports, require, module) {
var NoMoreProgression,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

module.exports = NoMoreProgression = (function(_super) {
  __extends(NoMoreProgression, _super);

  function NoMoreProgression() {
    var params;
    params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.params = params;
    NoMoreProgression.__super__.constructor.apply(this, arguments);
  }

  return NoMoreProgression;

})(Error);
});

;require.register("models/helpers/concept_by_ordering", function(exports, require, module) {
var NoMoreProgression, orderConceptsByList;

NoMoreProgression = require('/models/exceptions/progression_cycle_done');

module.exports = orderConceptsByList = function(q, concepts, ordering) {
  var c, chop_concept, concepts_by_ordering, err, f_strings, get_canonical_concept_value, last_concept, _conc, _i, _len,
    _this = this;
  if (q.attributes.type === 'image_to_word') {
    get_canonical_concept_value = function(c) {
      var answer_lang, txls;
      if ((c != null) && c) {
        answer_lang = q.attributes.filters.to_language;
        txls = _.first(c.getTranslationsToLang(answer_lang));
        return txls.get('concept_value');
      } else {
        return false;
      }
    };
  } else {
    chop_concept = function(a) {
      return a;
    };
    get_canonical_concept_value = function(c) {
      return c.get('concept_value');
    };
  }
  if (app.debug) {
    console.log("" + q.cid + " - " + user_prog_for_question.length + " run-throughs");
  }
  if (ordering.length === 0) {
    return concepts;
  }
  last_concept = app.userprogression.last();
  if (app.debug) {
    console.log("Last concept: ");
    console.log(last_concept);
  }
  concepts_by_ordering = [];
  for (_i = 0, _len = ordering.length; _i < _len; _i++) {
    c = ordering[_i];
    _conc = _.first(concepts.filter(function(v) {
      return get_canonical_concept_value(v) === c;
    }));
    if (_conc) {
      concepts_by_ordering.push(_conc);
    }
  }
  if (app.debug) {
    f_strings = ordered_by_frequency.map(function(f) {
      return "" + (progressionCorrectCountForConcept(f)) + " - " + (f.get('concept_value'));
    });
    if (f_strings.length > 0) {
      console.log(f_strings.join('\n'));
    }
  }
  if (concepts_by_ordering.length === 0) {
    if (app.debug) {
      console.log("No more concepts fitting progression");
    }
    err = new NoMoreProgression();
    throw err;
  }
  return concepts_by_ordering;
};
});

;require.register("models/helpers/concept_progression_sorter", function(exports, require, module) {
var NoMoreProgression, orderConceptsByProgression;

NoMoreProgression = require('/models/exceptions/progression_cycle_done');

module.exports = orderConceptsByProgression = function(q, concepts) {
  var countLessRepetitions, err, excluding_last_concept, f_strings, last_concept, max_repeats, notLast, ordered_by_frequency, progressionCorrectCountForConcept, reps, u, user_prog_for_question,
    _this = this;
  user_prog_for_question = app.userprogression.logs_for_question_in_cycle(q, q.get('cycle'));
  if (app.debug) {
    console.log("" + q.cid + " - " + user_prog_for_question.length + " run-throughs");
  }
  if (user_prog_for_question.length === 0) {
    return concepts;
  }
  max_repeats = _.max((function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = user_prog_for_question.length; _i < _len; _i++) {
      u = user_prog_for_question[_i];
      _results.push(u.get('cycle'));
    }
    return _results;
  })());
  if (!max_repeats) {
    max_repeats = false;
  }
  if (app.debug) {
    console.log("Currently at cycle <" + max_repeats + ">");
  }
  progressionCorrectCountForConcept = function(c) {
    var zups;
    zups = app.userprogression.correctLogsForConceptInQuestion(c, q);
    if (max_repeats) {
      zups = zups.filter(function(up) {
        return up.get('cycle') === max_repeats;
      });
    }
    return zups.length;
  };
  if (q.get('repetitions')) {
    reps = parseInt(q.get('repetitions'));
    if (app.debug) {
      console.log("question repetition count:" + q.get('repetitions'));
    }
  } else {
    reps = 3;
    q.set('repetitions', reps);
    if (app.debug) {
      console.log("question repetition not specified, default 3");
    }
  }
  countLessRepetitions = function(c) {
    return progressionCorrectCountForConcept(c) < reps + 1;
  };
  last_concept = app.userprogression.last();
  if (app.debug) {
    console.log("Last concept: ");
    console.log(last_concept);
  }
  if (last_concept) {
    notLast = function(c) {
      return c.get('concept_value') !== last_concept.get('question_concept_value');
    };
    excluding_last_concept = _.filter(concepts, notLast);
    if (excluding_last_concept.length === 0) {
      excluding_last_concept = concepts;
    }
  } else {
    excluding_last_concept = concepts;
  }
  ordered_by_frequency = _.sortBy(_.filter(excluding_last_concept, countLessRepetitions), progressionCorrectCountForConcept);
  if (app.debug) {
    f_strings = ordered_by_frequency.map(function(f) {
      return "" + (progressionCorrectCountForConcept(f)) + " - " + (f.get('concept_value'));
    });
    if (f_strings.length > 0) {
      console.log(f_strings.join('\n'));
    }
  }
  if (ordered_by_frequency.length === 0) {
    if (app.debug) {
      console.log("No more concepts fitting progression");
    }
    err = new NoMoreProgression();
    throw err;
  }
  return ordered_by_frequency;
};
});

;require.register("models/model", function(exports, require, module) {
var Model, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Model = (function(_super) {
  __extends(Model, _super);

  function Model() {
    _ref = Model.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  return Model;

})(Backbone.Model);
});

;require.register("models/question", function(exports, require, module) {
var LevelComplete, NoMoreProgression, Question, QuestionInstance, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

NoMoreProgression = require('/models/exceptions/progression_cycle_done');

LevelComplete = require('/models/exceptions/level_complete');

QuestionInstance = (function() {
  function QuestionInstance(generator, question, choices, answer, current_count, question_total, total_correct) {
    var choice;
    this.generator = generator;
    this.question = question;
    this.choices = choices;
    this.answer = answer;
    this.current_count = current_count;
    this.question_total = question_total;
    this.total_correct = total_correct;
    if (app.debug) {
      console.log("created instance");
    }
    if (app.debug) {
      console.log("cIDs for answer concepts:");
      console.log((function() {
        var _i, _len, _ref, _results;
        _ref = this.choices;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          choice = _ref[_i];
          _results.push(choice.cid);
        }
        return _results;
      }).call(this));
    }
    this.choices = _.shuffle(this.choices);
  }

  return QuestionInstance;

})();

module.exports = Question = (function(_super) {
  __extends(Question, _super);

  function Question() {
    _ref = Question.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Question.prototype.defaults = {
    cycle: 1,
    tries: 0
  };

  Question.prototype.cycle_for_progression = function() {
    var maximum, p;
    maximum = _.max((function() {
      var _i, _len, _ref1, _results;
      _ref1 = app.userprogression.logs_for_question(this);
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        p = _ref1[_i];
        _results.push(p.get('cycle'));
      }
      return _results;
    }).call(this));
    return _.max([maximum, 1]);
  };

  Question.prototype.total_correct_answers_for_question = function() {
    return app.userprogression.where({
      question_correct: true,
      question_category: this.get('category'),
      question_category_level: this.get('level'),
      cycle: this.get('cycle')
    }).length;
  };

  Question.prototype.user_completed_question = function(opts) {
    var c, concepts, concepts_for_question, correct_count, corrects, correctsForCQW, counts, cycle, logs_for_question, userprogression, _i, _len,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    userprogression = app.userprogression;
    correct_count = 2;
    if (opts.cycle) {
      cycle = opts.cycle;
    } else {
      cycle = this.get('cycle');
    }
    if (userprogression.length > 0) {
      logs_for_question = userprogression.correct_logs_for_question(this).filter(function(up) {
        return up.get('cycle') === cycle;
      });
      concepts_for_question = logs_for_question.map(function(up) {
        return up.get('question_concept');
      });
    } else {
      return false;
    }
    concepts = this.select_question_concepts(app.conceptdb);
    correctsForCQW = function(c, q, w) {
      return app.userprogression.correctLogsForConceptInQuestionInCycle(c, q, cycle).length;
    };
    counts = [];
    for (_i = 0, _len = concepts.length; _i < _len; _i++) {
      c = concepts[_i];
      corrects = correctsForCQW(c, this, cycle);
      if (corrects > correct_count) {
        corrects = correct_count;
      }
      counts.push(corrects);
    }
    if (_.uniq(counts).length === 1) {
      if (_.max(counts) === correct_count && _.uniq(counts)[0] === correct_count) {
        if (!opts.cycle) {
          console.log("incrementing cycle.");
          this.set('cycle', this.get('cycle') + 1);
        }
        return true;
      }
    }
    return false;
  };

  Question.prototype.user_completed_cycle = function() {
    var c, concepts, concepts_for_question, correct_count, corrects, correctsForCQW, counts, cycle, logs_for_question, userprogression, _i, _len,
      _this = this;
    userprogression = app.userprogression;
    correct_count = 2;
    if (opts.cycle) {
      cycle = opts.cycle;
    } else {
      cycle = this.get('cycle');
    }
    if (userprogression.length > 0) {
      logs_for_question = userprogression.correct_logs_for_question(this).filter(function(up) {
        return up.get('cycle') === cycle;
      });
      concepts_for_question = logs_for_question.map(function(up) {
        return up.get('question_concept');
      });
    } else {
      return false;
    }
    concepts = this.select_question_concepts(app.conceptdb);
    correctsForCQW = function(c, q, w) {
      return app.userprogression.correctLogsForConceptInQuestionInCycle(c, q, cycle).length;
    };
    counts = [];
    for (_i = 0, _len = concepts.length; _i < _len; _i++) {
      c = concepts[_i];
      corrects = correctsForCQW(c, this, cycle);
      if (corrects > correct_count) {
        corrects = correct_count;
      }
      counts.push(corrects);
    }
    if (_.uniq(counts).length === 1) {
      if (_.max(counts) === correct_count && _.uniq(counts)[0] === correct_count) {
        this.set('cycle', this.get('cycle') + 1);
        return true;
      }
    }
    return false;
  };

  Question.prototype.filter_concepts_by_media = function(concepts, media_size) {
    var filtered_concepts,
      _this = this;
    filtered_concepts = _.filter(concepts, function(c) {
      var i, imgs, _i, _j, _len, _len1;
      if (c.get('language') === 'img') {
        imgs = c.get('media').image;
        for (_i = 0, _len = imgs.length; _i < _len; _i++) {
          i = imgs[_i];
          if (i.size === app.media_size) {
            return true;
          }
        }
        return false;
      } else if (c.get('language') === 'mov') {
        imgs = c.get('media').video;
        for (_j = 0, _len1 = imgs.length; _j < _len1; _j++) {
          i = imgs[_j];
          if (i.size === app.media_size) {
            return true;
          }
        }
        return false;
      } else {
        return true;
      }
    });
    if (filtered_concepts.length === 0) {
      if (app.debug) {
        console.log("* Unable to filter by media type because concepts do not");
        console.log("  have a media type that matches device. Falling back to");
        console.log("  whatever is available.");
      }
      return concepts;
    }
    return filtered_concepts;
  };

  Question.prototype.select_question_concepts_by_progression = function(conceptdb) {
    var orderConceptsByProgression, userprog;
    userprog = app.userprogression;
    orderConceptsByProgression = require('./helpers/concept_progression_sorter');
    return orderConceptsByProgression(this, this.filter_concepts_by_media(this.select_question_concepts(conceptdb), app.media_size));
  };

  Question.prototype.select_question_concepts_by_ordering = function(conceptdb, ordering) {
    var orderConceptsByList;
    orderConceptsByList = require('./helpers/concept_by_ordering');
    return orderConceptsByList(this, this.filter_concepts_by_media(this.select_question_concepts(conceptdb), app.media_size), ordering);
  };

  Question.prototype.select_question_concepts = function(conceptdb) {
    var default_similarity, q_concepts, _answer_sim, _filters, _from, _to,
      _this = this;
    default_similarity = {
      'features': false,
      'semantics': false
    };
    _filters = this.get('filters');
    _answer_sim = this.get('answer_similarity') || default_similarity;
    _from = _filters.from_language;
    _to = _filters.to_language;
    q_concepts = conceptdb.filter(function(concept) {
      var semantics, target_language;
      if (concept.get('fails') === true) {
        return false;
      }
      semantics = _.intersection(concept.get('semantics'), _filters.semantics);
      target_language = concept.get('language') === _from;
      if (target_language && semantics.length > 0) {
        return true;
      } else {
        return false;
      }
    });
    return q_concepts;
  };

  Question.prototype.find_concepts = function(conceptdb, opts) {
    var a, act_ans, actual_answer, actual_answer_concepts, all_answer_poss, alt, alternate_translations, alternates, answer_possibilities, c, chop_concept, concept_values, concepts_left, concepts_total, default_similarity, difference, err, filterByLang, get_canonical_concept_value, inst, max_answers, pot_ans, potential_incorrect_answers, q_concepts, question, question_concepts, repeat_count, uniq_for_concept_value, userlang, userprogression, _answer_sim, _err, _error_msg, _filters, _from, _i, _j, _len, _len1, _ref1, _ref2, _to,
      _this = this;
    if (opts == null) {
      opts = {};
    }
    if (opts.repeat_count == null) {
      repeat_count = 0;
    }
    if (repeat_count > 5) {
      _err = new Error();
      console.log("Uh oh");
      throw _err;
    }
    userprogression = app.userprogression;
    if (this.tries > 3) {
      _error_msg = "Failed generating question " + (this.get('category')) + " - " + (this.get('level'));
      console.log(_error_msg);
      window.client_log.error(_error_msg);
      this.set('fails', true);
      return false;
    }
    userlang = ISOs.two_to_three(app.options.getSetting('help_language'));
    if (this.get('answers')) {
      max_answers = this.get('answers');
    } else {
      max_answers = 4;
    }
    answer_possibilities = [];
    default_similarity = {
      'features': false,
      'semantics': false
    };
    _filters = this.get('filters');
    _answer_sim = this.get('answer_similarity') || default_similarity;
    _from = _filters.from_language;
    _to = _filters.to_language;
    if (_to === "USERLANG") {
      console.log("USERLANG found, replacing with user help lang");
      console.log(userlang);
      _to = userlang;
    }
    question_concepts = this.select_question_concepts(conceptdb);
    if (this.attributes.type === 'word_to_image') {
      question_concepts = this.filter_concepts_by_media(question_concepts, app.media_size);
    }
    try {
      if ((opts.ordering != null) && opts.ordering) {
        q_concepts = this.select_question_concepts_by_ordering(question_concepts, opts.ordering);
      } else {
        q_concepts = this.select_question_concepts_by_progression(question_concepts);
      }
      if (app.debug) {
        console.log(q_concepts);
      }
    } catch (_error) {
      err = _error;
      if (err instanceof NoMoreProgression) {
        if (app.debug) {
          console.log("got NoMoreProgression...");
        }
        if (this.user_completed_question()) {
          throw new LevelComplete;
        } else {
          return this.find_concepts(conceptdb, {
            repeat_count: repeat_count + 1
          });
        }
      }
    }
    if (q_concepts.length > 0) {
      if (opts.ordering == null) {
        question = _.shuffle(q_concepts)[0];
        alternates = _.shuffle(q_concepts).slice(1);
      } else {
        question = _.first(q_concepts);
        alternates = _.shuffle(q_concepts).slice(1);
      }
    } else {
      console.log("No concepts left for question.");
      console.log(_filters);
      return false;
    }
    actual_answer_concepts = this.filter_concepts_by_media(question.getTranslationsToLang(_to), app.media_size);
    if (actual_answer_concepts.length === 0) {
      _error_msg = " * No translations to " + _to + " for " + (question.get('concept_value'));
      console.log(_error_msg);
      window.client_log.error(_error_msg);
      question.set('fails', true);
      this.tries += 1;
      return this.find_concepts(conceptdb);
    }
    filterByLang = function(lang, concepts) {
      var _this = this;
      return concepts.filter(function(o) {
        return o.get('language') === lang;
      });
    };
    alternate_translations = filterByLang(_to, _.flatten((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = alternates.length; _i < _len; _i++) {
        alt = alternates[_i];
        _results.push(conceptdb.getTranslationsOf(alt));
      }
      return _results;
    })()));
    answer_possibilities = alternate_translations;
    actual_answer = _.shuffle(actual_answer_concepts)[0];
    potential_incorrect_answers = conceptdb.filter(function(concept) {
      var semantics, target_language;
      target_language = concept.get('language') === _to;
      if (_answer_sim.semantics) {
        semantics = _.intersection(concept.get('semantics'), _answer_sim.semantics);
        if (target_language && concept !== actual_answer && semantics.length > 0) {
          return true;
        } else {
          return false;
        }
      } else {
        if (target_language && concept !== actual_answer) {
          return true;
        } else {
          return false;
        }
      }
    });
    if (this.attributes.type === 'word_to_image') {
      chop_concept = function(a) {
        return a.split('/').slice(-1)[0];
      };
      get_canonical_concept_value = function(c) {
        var question_concept_value, question_lang, txls;
        question_concept_value = question.get('concept_value');
        question_lang = question.get('language');
        txls = _.first(c.getTranslationsToLang(question_lang));
        return txls.get('concept_value');
      };
    } else {
      chop_concept = function(a) {
        return a;
      };
      get_canonical_concept_value = function(c) {
        return c.get('concept_value');
      };
    }
    uniq_for_concept_value = function(cs) {
      var c, _cs, _cv, _cvs, _i, _len;
      _cs = [];
      _cvs = [];
      for (_i = 0, _len = cs.length; _i < _len; _i++) {
        c = cs[_i];
        _cv = get_canonical_concept_value(c);
        if (__indexOf.call(_cvs, _cv) >= 0) {
          continue;
        }
        _cs.push(c);
        _cvs.push(_cv);
      }
      return _cs;
    };
    potential_incorrect_answers = _.shuffle(uniq_for_concept_value(potential_incorrect_answers));
    answer_possibilities = this.filter_concepts_by_media(answer_possibilities, app.media_size);
    answer_possibilities = answer_possibilities.slice(0, max_answers - 1);
    all_answer_poss = [actual_answer];
    all_answer_poss = all_answer_poss.concat(answer_possibilities);
    all_answer_poss = uniq_for_concept_value(all_answer_poss);
    if (all_answer_poss.length < max_answers) {
      if (app.debug) {
        console.log("Things came short, filling in...");
      }
      difference = max_answers - all_answer_poss.length;
      concept_values = all_answer_poss.map(get_canonical_concept_value);
      _ref1 = _.range(0, difference);
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        c = _ref1[_i];
        act_ans = get_canonical_concept_value(actual_answer);
        _ref2 = _.shuffle(potential_incorrect_answers);
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          a = _ref2[_j];
          pot_ans = get_canonical_concept_value(a);
          if ((pot_ans !== act_ans) && !(__indexOf.call(all_answer_poss, a) >= 0)) {
            all_answer_poss.push(a);
            break;
          }
        }
      }
    }
    if (question && all_answer_poss.length > 0 && actual_answer) {
      concepts_left = concepts_total - q_concepts.length;
      concepts_total = question_concepts.length;
      inst = new QuestionInstance(this, question, all_answer_poss, actual_answer, concepts_left, concepts_total, this.total_correct_answers_for_question());
    } else {
      console.log(" * Couldn't generate a question instance for " + (this.get('name')));
      console.log("   removing question from cycle.");
      inst = false;
      this.set('fails', true);
    }
    return inst;
  };

  return Question;

})(Backbone.Model);
});

;require.register("models/questiondb", function(exports, require, module) {
var LevelComplete, Question, QuestionDB, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Question = require('models/question');

LevelComplete = require('/models/exceptions/level_complete');

module.exports = QuestionDB = (function(_super) {
  __extends(QuestionDB, _super);

  function QuestionDB() {
    _ref = QuestionDB.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  QuestionDB.prototype.model = Question;

  QuestionDB.prototype.url = function() {
    return app.server.path + "/data/leksa_questions.json";
  };

  QuestionDB.prototype.initialize = function() {
    var _this = this;
    return this.fetch({
      success: function() {
        var mod_count;
        app.loadingTracker.markReady('leksa_questions.json');
        mod_count = app.questiondb.models.length;
        return console.log("fetched leksa_questions.json (" + mod_count + ")");
      }
    });
  };

  QuestionDB.prototype.removeNonFunctioning = function(qs) {
    return qs.filter(function(c) {
      var _fails;
      _fails = c.get('fails');
      if (!_fails) {
        return true;
      }
      if (_fails && _fails === false) {
        return false;
      }
    });
  };

  QuestionDB.prototype.filterQuestionsByCategory = function(category) {
    var adjusted_qs, cat, cat_semantics, new_q, q, qs, _filters, _i, _len, _sims;
    qs = this.removeNonFunctioning(this.where({
      'category': category
    }));
    if (qs.length === 0) {
      qs = this.removeNonFunctioning(this.where({
        'category': 'DEFAULT_GROUP'
      }));
      cat = _.first(app.categories.where({
        category: category
      }));
      cat_semantics = cat.get('semantics');
      adjusted_qs = [];
      for (_i = 0, _len = qs.length; _i < _len; _i++) {
        q = qs[_i];
        new_q = q.clone();
        new_q.set('category', category);
        _filters = new_q.get('filters');
        _sims = new_q.get('answer_similarity');
        _filters.semantics = cat_semantics;
        _sims.semantics = cat_semantics;
        adjusted_qs.push(new_q);
      }
      qs = adjusted_qs;
    }
    return qs;
  };

  QuestionDB.prototype.orderQuestionsByProgression = function(qs, user_cycle) {
    var questionByProg, userprogression,
      _this = this;
    userprogression = app.userprogression;
    questionByProg = function(questions, user_cycle) {
      var filtered_questions, _filtered_questions;
      if (app.debug) {
        console.log("choosing question by progression");
      }
      _filtered_questions = questions.filter(function(q) {
        return !q.user_completed_question({
          cycle: user_cycle
        });
      });
      filtered_questions = _filtered_questions.map(function(q) {
        return {
          'question': q,
          'level': q.get('level')
        };
      });
      filtered_questions = _.sortBy(filtered_questions, 'level');
      if (filtered_questions.length > 0) {
        return [_.first(filtered_questions).question];
      } else {
        return false;
      }
    };
    return _.shuffle(questionByProg(this.removeNonFunctioning(qs), user_cycle));
  };

  QuestionDB.prototype.selectQuestionByProg = function(category, level_constraint) {
    if (level_constraint == null) {
      level_constraint = false;
    }
    return this.selectQuestion(category, level_constraint);
  };

  QuestionDB.prototype.selectQuestion = function(category, level_constraint, ordering) {
    var category_qs, completed, current_question_cycle, e, level_constraint_qs, max_tries, progression_qs, progression_qs_next, q, qs, question_instance, tries, user_cycle, _msg_q_cycle, _ref1;
    if (level_constraint == null) {
      level_constraint = false;
    }
    if (ordering == null) {
      ordering = false;
    }
    _ref1 = [0, 5], tries = _ref1[0], max_tries = _ref1[1];
    if (level_constraint === false) {
      level_constraint = function(level) {
        return true;
      };
    }
    question_instance = false;
    while (!question_instance && tries <= max_tries) {
      category_qs = this.filterQuestionsByCategory(category);
      level_constraint_qs = category_qs.filter(level_constraint);
      if (app.debug) {
        console.log("Level constraint questions: ");
        console.log((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = level_constraint_qs.length; _i < _len; _i++) {
            q = level_constraint_qs[_i];
            _results.push("" + (q.get('category')) + "/" + (q.get('level')));
          }
          return _results;
        })());
      }
      if (level_constraint_qs.length > 0) {
        qs = level_constraint_qs;
      } else {
        qs = category_qs;
      }
      completed = false;
      user_cycle = app.userprogression.cycle_for_category(category);
      if (this.needs_next) {
        user_cycle += 1;
      }
      progression_qs = this.orderQuestionsByProgression(qs, user_cycle);
      if (app.debug) {
        console.log("Ordered by progression: ");
        console.log((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = progression_qs.length; _i < _len; _i++) {
            q = progression_qs[_i];
            _results.push("" + (q.get('category')) + "/" + (q.get('level')));
          }
          return _results;
        })());
      }
      if (progression_qs.length === 0) {
        progression_qs_next = this.orderQuestionsByProgression(qs, user_cycle + 1);
        if (app.debug) {
          console.log("Ordered by progression plus one: ");
          console.log((function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = progression_qs_next.length; _i < _len; _i++) {
              q = progression_qs_next[_i];
              _results.push("" + (q.get('category')) + "/" + (q.get('level')));
            }
            return _results;
          })());
        }
      } else {
        progression_qs_next = [];
      }
      if (progression_qs_next.length > 0 && progression_qs.length === 0 && !this.needs_next) {
        if (app.debug) {
          console.log("Uh oh, this.");
        }
        user_cycle += 1;
        progression_qs = this.orderQuestionsByProgression(qs, user_cycle);
        completed = true;
      }
      this.needs_next = false;
      if (progression_qs) {
        qs = progression_qs;
      } else {
        qs = qs;
      }
      if (qs.length === 0) {
        return false;
      }
      q = _.first(qs);
      q.set('cycle', user_cycle);
      current_question_cycle = q.cycle_for_progression();
      if (app.debug) {
        console.log("current cycle: " + current_question_cycle);
        console.log("question level: " + (q.get('level')));
        console.log("user's cycle for category: " + current_question_cycle);
      }
      try {
        question_instance = q.find_concepts(app.conceptdb, {
          ordering: ordering
        });
        if (app.debug) {
          _msg_q_cycle = question_instance.generator.get('cycle');
          console.log("question cycle: " + _msg_q_cycle);
        }
        if (completed) {
          if (app.debug) {
            console.log("question cycle complete for: " + q);
          }
          question_instance = false;
          this.needs_next = true;
          return question_instance;
        }
      } catch (_error) {
        e = _error;
        console.log("TODO: caught LevelComplete");
        if (e instanceof LevelComplete) {
          question_instance = false;
          if (app.debug) {
            console.log("question cycle complete for: " + q);
          }
        }
      }
      tries += 1;
    }
    return question_instance;
  };

  return QuestionDB;

})(Backbone.Collection);
});

;require.register("models/session", function(exports, require, module) {
var Session, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = Session = (function(_super) {
  __extends(Session, _super);

  function Session() {
    _ref = Session.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Session.prototype.defaults = {
    access_token: null,
    user_id: null
  };

  Session.prototype.initialize = function() {
    return this.load();
  };

  Session.prototype.authenticated = function() {
    return Boolean(this.get("access_token"));
  };

  Session.prototype.save = function(auth_hash) {
    $.cookie('user_id', auth_hash.id);
    return $.cookie('access_token', auth_hash.access_token);
  };

  Session.prototype.load = function() {
    return this.set({
      user_id: $.cookie('user_id'),
      access_token: $.cookie('access_token')
    });
  };

  return Session;

})(Backbone.Model);
});

;require.register("models/user_log_entry", function(exports, require, module) {
var UserLogEntry, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = UserLogEntry = (function(_super) {
  __extends(UserLogEntry, _super);

  function UserLogEntry() {
    _ref = UserLogEntry.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  UserLogEntry.prototype.url = "/user/data/log/";

  UserLogEntry.prototype.attributes = {
    game_name: false,
    question_concept: false,
    question_correct: false,
    cycle: false
  };

  UserLogEntry.prototype.do_not_push = ["sid", "dirty"];

  UserLogEntry.prototype.toJSON = function(options) {
    var attrs, i, _i, _len, _ref1;
    attrs = this.attributes;
    _ref1 = this.do_not_push;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      i = _ref1[_i];
      delete attrs[i];
    }
    return _.clone(attrs);
  };

  UserLogEntry.prototype.initialize = function() {
    this.set('sid', 'new');
    this.set('dirty', true);
    return this.set('_id', this.cid);
  };

  return UserLogEntry;

})(Backbone.Model);
});

;require.register("models/user_progression", function(exports, require, module) {
var UserLogEntry, UserProgression, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

UserLogEntry = require('models/user_log_entry');

module.exports = UserProgression = (function(_super) {
  __extends(UserProgression, _super);

  function UserProgression() {
    _ref = UserProgression.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  UserProgression.prototype.url = "/user/data/log/";

  UserProgression.prototype.model = UserLogEntry;

  UserProgression.prototype.parse = function(resp) {
    return resp.data;
  };

  UserProgression.prototype.logs_for_category_name = function(c_name) {
    return this.where({
      question_category: c_name
    });
  };

  UserProgression.prototype.points_for_category_name = function(c_name) {
    var points;
    points = this.logs_for_category_name(c_name).map(function(l) {
      return l.get('points');
    });
    return _.reduce(points, (function(memo, num) {
      return memo + num;
    }), 0);
  };

  UserProgression.prototype.cycle_for_category = function(c_name) {
    var maximum, p;
    maximum = _.max((function() {
      var _i, _len, _ref1, _results;
      _ref1 = this.logs_for_category_name(c_name);
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        p = _ref1[_i];
        _results.push(p.get('cycle'));
      }
      return _results;
    }).call(this));
    return _.max([maximum, 1]);
  };

  UserProgression.prototype.logs_for_question = function(q) {
    return this.where({
      question_category: q.get('category'),
      question_category_level: q.get('level')
    });
  };

  UserProgression.prototype.logs_for_question_in_cycle = function(q, w) {
    return this.where({
      question_category: q.get('category'),
      question_category_level: q.get('level'),
      cycle: w
    });
  };

  UserProgression.prototype.correct_logs_for_question = function(q) {
    return this.where({
      question_category: q.get('category'),
      question_category_level: q.get('level'),
      question_correct: true
    });
  };

  UserProgression.prototype.correctLogsForConceptInQuestion = function(c, q) {
    return this.where({
      question_category: q.get('category'),
      question_category_level: q.get('level'),
      question_concept: c.get('concept_value'),
      question_correct: true
    });
  };

  UserProgression.prototype.correctLogsForConceptInQuestionInCycle = function(c, q, w) {
    return this.where({
      question_category: q.get('category'),
      question_category_level: q.get('level'),
      question_concept: c.get('concept_value'),
      question_correct: true,
      cycle: w
    });
  };

  UserProgression.prototype.initialize = function() {
    this.storage = new Offline.Storage('leksa-user-progression', this);
    if (app.has_user) {
      if (navigator.onLine) {
        return this.fetch();
      }
    }
  };

  UserProgression.prototype.countPoints = function() {
    var a, total, _i, _len, _ref1;
    total = 0;
    _ref1 = this.pluck('points');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      a = _ref1[_i];
      if (a && a !== void 0) {
        total += a;
      }
    }
    return total;
  };

  UserProgression.prototype.logActivity = function(opts) {
    var log;
    log = this.create(opts);
    log.set('dirty', true);
    if (app.user) {
      this.storage.sync.push();
    }
    return log;
  };

  UserProgression.prototype.collateConcepts = function(conceptdb) {
    var boolToInt, c, c_name, c_vals, concept_correct, grouped_values, sorted_values, totals, v, _i, _len, _ref1, _v_correct, _v_total, _vals;
    boolToInt = function(b) {
      switch (b) {
        case true:
          return 1;
        case false:
          return 0;
      }
    };
    concept_correct = [];
    _ref1 = this.models;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      c = _ref1[_i];
      concept_correct.push([c.get('question_concept_value'), boolToInt(c.get('question_correct'))]);
    }
    sorted_values = _.sortBy(concept_correct, function(m) {
      return m[0];
    });
    grouped_values = _.groupBy(sorted_values, function(m) {
      return m[0];
    });
    totals = {};
    for (c_name in grouped_values) {
      c_vals = grouped_values[c_name];
      _vals = _.flatten([
        (function() {
          var _j, _len1, _results;
          _results = [];
          for (_j = 0, _len1 = c_vals.length; _j < _len1; _j++) {
            v = c_vals[_j];
            _results.push(v[1]);
          }
          return _results;
        })()
      ]);
      _v_correct = _.reduce(_vals, function(a, m) {
        return a + m;
      });
      _v_total = _vals.length;
      totals[c_name] = [_v_correct, _v_total];
    }
    return totals;
  };

  UserProgression.prototype.totalCorrect = function() {
    var models;
    models = this.models.filter(function(m) {
      return m.get('question_correct') === true;
    });
    return models.length;
  };

  return UserProgression;

})(Backbone.Collection);
});

;require.register("models/user_settings", function(exports, require, module) {
var UserSetting, UserSettings, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

UserSetting = require('models/usersetting');

module.exports = UserSettings = (function(_super) {
  __extends(UserSettings, _super);

  function UserSettings() {
    _ref = UserSettings.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  UserSettings.prototype.url = "/user/settings/";

  UserSettings.prototype.model = UserSetting;

  UserSettings.prototype.default_setting_values = {
    enable_cache: false,
    enable_audio: true,
    highscore_visible: true,
    interface_language: 'nob',
    help_language: 'nob'
  };

  UserSettings.prototype.getSetting = function(setting) {
    var new_s, s, val;
    s = this.where({
      setting_key: setting
    });
    if (s.length > 0) {
      return s[0].get('setting_value');
    } else {
      val = this.default_setting_values[setting];
      if (val != null) {
        new_s = this.setSetting(setting, val);
        return val;
      }
    }
    return null;
  };

  UserSettings.prototype.setLanguage = function(value, opts) {
    if (opts == null) {
      opts = {};
    }
    return app.switch_locale(value, opts);
  };

  UserSettings.prototype.setSettings = function(values, opts) {
    var k, v;
    if (opts == null) {
      opts = {};
    }
    for (k in values) {
      v = values[k];
      this.setSetting(k, v);
    }
    if (opts.store != null) {
      return this.storage.sync.push();
    }
  };

  UserSettings.prototype.setSetting = function(key, val, opts) {
    var new_setting, setting;
    if (opts == null) {
      opts = {};
    }
    setting = this.where({
      setting_key: key
    });
    if (setting.length > 0) {
      this.remove(setting);
    }
    new_setting = this.create({
      setting_key: key,
      setting_value: val
    });
    new_setting.set('dirty', true);
    if (key === 'interface_language') {
      this.setLanguage(val);
    }
    if (opts.success) {
      opts.success();
    }
    return new_setting;
  };

  UserSettings.prototype.setDefaults = function(opts) {
    var k, v, _results;
    _results = [];
    for (k in opts) {
      v = opts[k];
      _results.push(this.setSetting(k, v));
    }
    return _results;
  };

  UserSettings.prototype.parse = function(response, opts) {
    return response.settings;
  };

  UserSettings.prototype.initialize = function() {
    this.storage = new Offline.Storage('user-settings', this);
    if (!app.user) {
      return this.setDefaults(this.default_setting_values);
    }
  };

  return UserSettings;

})(Backbone.Collection);
});

;require.register("models/usersetting", function(exports, require, module) {
var UserSetting, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = UserSetting = (function(_super) {
  __extends(UserSetting, _super);

  function UserSetting() {
    _ref = UserSetting.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  UserSetting.prototype.url = "/user/settings/";

  UserSetting.prototype.defaults = {
    setting_key: false,
    setting_value: false
  };

  UserSetting.prototype.do_not_push = ["sid", "dirty"];

  UserSetting.prototype.initialize = function() {
    this.set('sid', 'new');
    this.set('dirty', true);
    return this.set('_id', this.cid);
  };

  UserSetting.prototype.toJSON = function(options) {
    var attrs, i, _i, _len, _ref1;
    attrs = this.attributes;
    _ref1 = this.do_not_push;
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      i = _ref1[_i];
      delete attrs[i];
    }
    return _.clone(attrs);
  };

  return UserSetting;

})(Backbone.Model);
});

;require.register("routers/router", function(exports, require, module) {
var CategoryGames, CategoryMenu, ConceptList, ErrorView, FrontPage, GlobalOptionsView, InfoView, LearnView, LeksaView, LevelComplete, LoadingView, Router, SplashView, UserStats, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LeksaView = require('views/games/leksa');

LearnView = require('views/games/learn');

CategoryMenu = require('views/categories/categories');

CategoryGames = require('views/categories/category');

ConceptList = require('views/concepts/list');

GlobalOptionsView = require('views/users/options');

UserStats = require('views/users/stats');

FrontPage = require('views/intro/view');

ErrorView = require('views/error/view');

LoadingView = require('views/intro/loading');

SplashView = require('views/splash/splash');

InfoView = require('views/info/info');

LevelComplete = require('views/games/level_complete');

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    _ref = Router.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  Router.prototype.initialize = function() {
    $('.back').live('click', function(event) {
      window.history.back();
      return false;
    });
    this.firstPage = true;
    app.userStats = new UserStats();
    app.categoryMenu = new CategoryMenu();
    app.categoryGames = new CategoryGames();
    app.errorView = new ErrorView();
    app.frontPage = new FrontPage();
    app.loadingView = new LoadingView();
    app.splashView = new SplashView();
    app.infoView = new InfoView();
    return app.levelComplete = new LevelComplete();
  };

  Router.prototype.routes = {
    '': 'splash',
    '#splash': 'splash',
    'index': 'index',
    '#index': 'index',
    'frontPage': 'frontPage',
    '#frontPage': 'frontPage',
    'options': 'options',
    '#options': 'options',
    'error': 'errorPage',
    '#error': 'errorPage',
    'reset': 'reset',
    '#reset': 'reset',
    'loading': 'loading',
    '#loading': 'loading',
    'stats': 'userStats',
    '#stats': 'userStats',
    'infoPage': 'infoPage',
    '#infoPage': 'infoPage',
    'mainMenu': 'categoryMenu',
    '#mainMenu': 'categoryMenu',
    'categoryMenu': 'categoryMenu',
    '#categoryMenu': 'categoryMenu',
    'category/:name': 'categoryGames',
    '#category/:name': 'categoryGames',
    'level_complete': 'level_complete',
    '#level_complete': 'level_complete',
    'category_complete': 'category_complete',
    '#category_complete': 'category_complete',
    'leksa/:level/:category': 'learn_and_practice',
    '#leksa/:level/:category': 'learn_and_practice',
    'conceptSet/:category': 'conceptSet',
    '#conceptSet/:category': 'conceptSet'
  };

  Router.prototype.index = function() {
    var configured_already;
    configured_already = DSt.get('gielese-configured');
    if (configured_already) {
      return this.changePage(app.categoryMenu);
    } else {
      app.frontPage = new FrontPage();
      return this.changePage(app.frontPage);
    }
  };

  Router.prototype.frontPage = function() {
    app.frontPage = new FrontPage();
    return this.changePage(app.frontPage);
  };

  Router.prototype.loading = function() {
    return this.changePage(app.loadingView);
  };

  Router.prototype.infoPage = function() {
    return this.changePage(app.infoView);
  };

  Router.prototype.level_complete = function() {
    app.levelComplete = new LevelComplete();
    app.levelComplete.category = false;
    return this.changePage(app.levelComplete);
  };

  Router.prototype.category_complete = function() {
    app.levelComplete = new LevelComplete();
    app.levelComplete.category = true;
    return this.changePage(app.levelComplete);
  };

  Router.prototype.splash = function() {
    var time,
      _this = this;
    this.changePage(app.splashView);
    if (DSt.get('skip-splash') != null) {
      time = 500;
    } else {
      time = 5000;
    }
    return setTimeout(function() {
      var configured_already;
      configured_already = DSt.get('gielese-configured', false);
      if (configured_already) {
        app.categoryMenu = new CategoryMenu();
        return _this.fadePage(app.categoryMenu);
      } else {
        app.frontPage = new FrontPage();
        return _this.fadePage(app.frontPage);
      }
    }, time);
  };

  Router.prototype.reset = function() {
    DSt.set('gielese-configured', false);
    return window.location = '/';
  };

  Router.prototype.userStats = function() {
    app.userStats = new UserStats();
    return this.changePage(app.userStats);
  };

  Router.prototype.categoryMenu = function() {
    app.categoryMenu = new CategoryMenu();
    app.categoryMenu.initialize();
    return this.changePage(app.categoryMenu);
  };

  Router.prototype.categoryGames = function(name) {
    app.categoryGames = new CategoryGames();
    app.categoryGames.category = name;
    app.categoryGames.initialize();
    return this.changePage(app.categoryGames);
  };

  Router.prototype.learn_and_practice = function(level, category) {
    var _this = this;
    return app.loadingTracker.waitForDeps({
      extra_test: function() {
        return app.conceptdb.models.length > 0 && app.questiondb.models.length > 0 && app.categories.models.length > 0;
      },
      failed: function() {
        return console.log("Uh oh!");
      },
      ready: function() {
        level = parseInt(level);
        if (level === 1) {
          app.leksaView = new LearnView({
            attributes: {
              leksa_category: category,
              level_constraint: level
            }
          });
        } else if (level > 1) {
          app.leksaView = new LeksaView({
            attributes: {
              leksa_category: category,
              level_constraint: level
            }
          });
        }
        app.leksaView.preselected_q = app.leksaView.selectQuestionForRendering();
        app.leksaView.pregenerated = true;
        app.leksaView.playQuestionSound();
        app.leksaView.initialize();
        _this.changePage(app.leksaView);
        return app.leksaView.viewedOnce = true;
      }
    });
  };

  Router.prototype.errorPage = function() {
    return this.changePage(app.errorView);
  };

  Router.prototype.options = function() {
    app.globalOptionsView = new GlobalOptionsView();
    return this.changePage(app.globalOptionsView);
  };

  Router.prototype.conceptSet = function(category) {
    var _this = this;
    return app.loadingTracker.waitForDeps({
      extra_test: function() {
        return app.conceptdb.models.length > 0;
      },
      ready: function() {
        app.conceptList = new ConceptList();
        app.conceptList.for_category = category;
        app.conceptList.initialize();
        return _this.changePage(app.conceptList);
      },
      failed: function() {
        return console.log("Oh craapp");
      }
    });
  };

  Router.prototype.refreshCurrentPage = function() {
    $('[data-role="page"]').trigger("pagecreate");
    return true;
  };

  Router.prototype.changePage = function(page) {
    var transition;
    $(page.el).attr('data-role', 'page');
    page.render();
    $('body').append($(page.el));
    transition = $.mobile.defaultPageTransition;
    if (this.firstPage) {
      transition = 'none';
      this.firstPage = false;
    }
    $.mobile.changePage($(page.el), {
      changeHash: false,
      transition: transition
    });
    return false;
  };

  Router.prototype.fadePage = function(page) {
    var transition;
    $(page.el).attr('data-role', 'page');
    page.render();
    $('body').append($(page.el));
    transition = $.mobile.defaultPageTransition;
    transition = 'fade';
    $.mobile.changePage($(page.el), {
      changeHash: false,
      transition: transition
    });
    return false;
  };

  return Router;

})(Backbone.Router);
});

;require.register("sample_data/sample_concepts", function(exports, require, module) {

});

;require.register("tests/auth_tests", function(exports, require, module) {
var AuthTests;

module.exports = AuthTests = (function() {
  AuthTests.prototype.test_order = [];

  AuthTests.prototype.run = function() {
    return true;
  };

  function AuthTests() {}

  return AuthTests;

})();
});

;require.register("tests/question_tests", function(exports, require, module) {
var QuestionTests;

module.exports = QuestionTests = (function() {
  QuestionTests.prototype.test_order = ['duplicate_four_questions'];

  QuestionTests.prototype.filter_concepts_by_media_size = function() {
    var concepts, concepts_f, media_size, pluck_values;
    pluck_values = function(c) {
      return c.attributes.concept_value;
    };
    media_size = 'small';
    concepts = app.conceptdb.where({
      language: "img",
      semantics: ["FOOD"]
    });
    console.log(concepts.map(pluck_values));
    concepts_f = this.filter_concepts_by_media(concepts, media_size);
    console.log(concepts_f.map(pluck_values));
    return false;
  };

  QuestionTests.prototype.duplicate_four_questions = function() {
    var db, errors, filenames, success, vs;
    db = app.questiondb;
    errors = [];
    success = true;
    vs = db.where({
      type: "word_to_image",
      category: "TEST"
    })[0].find_concepts(app.conceptdb, app.userprogression).choices.map(function(o) {
      return o.attributes.concept_value;
    });
    filenames = vs.map(function(a) {
      return a.split('/').slice(-1)[0];
    });
    if (_.uniq(filenames).length !== 4) {
      console.log(filenames);
      success = false;
      errors.push("* Filenames are same, directory structure differs");
    }
    if (_.uniq(vs).length !== 4) {
      console.log(vs);
      success = false;
      errors.push("* Paths are the same");
    }
    return [success, errors];
  };

  QuestionTests.prototype.run = function(iterations) {
    var a, err, errors, status, status_str, _i, _len, _ref, _ref1, _results, _th;
    if (iterations == null) {
      iterations = 4;
    }
    status_str = function(a) {
      if (a) {
        return "PASS";
      } else {
        return "FAIL";
      }
    };
    _th = this;
    _ref = this.test_order;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      a = _ref[_i];
      _ref1 = _th[a](), status = _ref1[0], errors = _ref1[1];
      console.log("" + (status_str(status)) + ": " + a);
      if (errors.length > 0) {
        _results.push((function() {
          var _j, _len1, _results1;
          _results1 = [];
          for (_j = 0, _len1 = errors.length; _j < _len1; _j++) {
            err = errors[_j];
            _results1.push(console.log("  " + err));
          }
          return _results1;
        })());
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  function QuestionTests() {}

  return QuestionTests;

})();
});

;require.register("tests/tests", function(exports, require, module) {
var AuthTests, QuestionTests, Tests;

QuestionTests = require('./question_tests');

AuthTests = require('./auth_tests');

module.exports = Tests = (function() {
  Tests.prototype.test_order = ['questions', 'auth'];

  Tests.prototype.run = function() {
    return true;
  };

  function Tests() {
    this.questions = new QuestionTests();
    this.auth = new AuthTests();
  }

  return Tests;

})();
});

;require.register("views/categories/categories", function(exports, require, module) {
var CategoriesList, CategoryMenu, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CategoriesList = require('./templates/categories');

module.exports = CategoryMenu = (function(_super) {
  __extends(CategoryMenu, _super);

  function CategoryMenu() {
    _ref = CategoryMenu.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  CategoryMenu.prototype.events = {
    "click #login_button": 'displayLogin',
    "click #log_out": 'logout',
    "click #userinfo_button": 'displayUserInfo',
    "click .category_name_play": 'playAudioBefore',
    "click a": "clickSound"
  };

  CategoryMenu.prototype.id = "category_menu";

  CategoryMenu.prototype.clickSound = function(evt) {
    app.soundEffects.click();
    return true;
  };

  CategoryMenu.prototype.logout = function(evt) {
    DSt.set('gielese-configured', false);
    return window.location.hash = "frontPage";
  };

  CategoryMenu.prototype.displayLogin = function(evt) {
    var _this = this;
    if (app.user) {
      window.location.hash = 'stats';
      return true;
    }
    return app.auth.render_authentication_popup(this.$el, {
      success: function() {
        var un;
        un = app.user.username;
        _this.$el.find('#login_button').find('.action').html(" ");
        _this.$el.find('#login_button').find('.user').html(un);
        _this.$el.find('#login_button').attr('href', "#stats");
        return setTimeout(function() {
          return app.auth.hide_authentication_popup(_this.$el);
        }, 250);
      }
    });
  };

  CategoryMenu.prototype.template = CategoriesList;

  CategoryMenu.prototype.render = function() {
    var c, categories, chunks, labels, withLabel, _labels,
      _this = this;
    categories = app.categories.where({
      main_menu: true
    });
    labels = 'cba';
    _labels = labels.split('');
    withLabel = function(c) {
      var lab;
      if (_labels.length === 0) {
        _labels = labels.split('');
      }
      lab = _labels.pop(0);
      return [c, lab];
    };
    chunks = window.arrayChunk((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = categories.length; _i < _len; _i++) {
        c = categories[_i];
        _results.push(withLabel(c));
      }
      return _results;
    })(), 3);
    this.$el.html(this.template({
      categories: chunks
    }));
    return this;
  };

  return CategoryMenu;

})(Backbone.View);
});

;require.register("views/categories/category", function(exports, require, module) {
var Category, CategoryGames, CategoryTemplate, SubcategoryTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Category = require('models/category');

CategoryTemplate = require('./templates/category');

SubcategoryTemplate = require('./templates/subcategory');

module.exports = CategoryGames = (function(_super) {
  __extends(CategoryGames, _super);

  function CategoryGames() {
    _ref = CategoryGames.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  CategoryGames.prototype.id = "category_view";

  CategoryGames.prototype.events = {
    "click a": "clickSound"
  };

  CategoryGames.prototype.clickSound = function(evt) {
    app.soundEffects.click();
    return true;
  };

  CategoryGames.prototype.template = function(params) {
    if (params.subcategory) {
      return SubcategoryTemplate(params);
    } else {
      return CategoryTemplate(params);
    }
  };

  CategoryGames.prototype.render = function() {
    var c, cat, category_image, cats, children, chunks, labels, subcategory, withLabel, _labels,
      _this = this;
    cats = app.categories.where({
      category: this.category
    });
    if (cats.length > 0) {
      cat = cats[0];
    }
    subcategory = cat.children();
    if (subcategory) {
      labels = 'cba';
      _labels = labels.split('');
      withLabel = function(c) {
        var lab;
        if (_labels.length === 0) {
          _labels = labels.split('');
        }
        lab = _labels.pop(0);
        return [c, lab];
      };
      chunks = window.arrayChunk((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = subcategory.length; _i < _len; _i++) {
          c = subcategory[_i];
          _results.push(withLabel(c));
        }
        return _results;
      })(), 3);
      subcategory = chunks;
    } else {
      children = false;
    }
    window.cat = cat;
    if (cat.hasImage()) {
      category_image = cat.hasImage();
    } else {
      category_image = '';
    }
    this.$el.html(this.template({
      category: cat,
      subcategory: subcategory
    }));
    this.$el.css({
      "background-image": "url('" + category_image + "')",
      "background-size": "cover",
      "background-repeat": "no-repeat",
      "background-position": "center"
    });
    return this;
  };

  return CategoryGames;

})(Backbone.View);
});

;require.register("views/categories/templates/categories", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var background_img, cat, category, group, label, name, subcat, _i, _j, _len, _len1, _ref, _ref1;
    
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-left-arrow">\n            <a href="#" id="log_out">\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content" id="main_menu_content">\n\n    <div id="category_links">\n\n        <div class="ui-grid-b">\n        ');
    
      _ref = this.categories;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        group = _ref[_i];
        __out.push('\n            ');
        for (_j = 0, _len1 = group.length; _j < _len1; _j++) {
          _ref1 = group[_j], category = _ref1[0], label = _ref1[1];
          __out.push('\n                ');
          cat = category.get('category');
          __out.push('\n                ');
          name = category.get('name');
          __out.push('\n                ');
          subcat = category.get('children').length > 0;
          __out.push('\n\n                <div class="ui-block-');
          __out.push(label);
          __out.push('">\n                    ');
          if (category.get('grayed_out')) {
            __out.push('\n                    <a class="square grayed"\n                    ');
          } else {
            __out.push('\n                        ');
            if (subcat) {
              __out.push('\n                            <a class="square"\n                        ');
            } else {
              __out.push('\n                            <a class="square category_name_play"\n                               data-lemma="');
              __out.push(name);
              __out.push('"\n                        ');
            }
            __out.push('\n                    ');
          }
          __out.push('\n                       href="#category/');
          __out.push(cat);
          __out.push('"\n                       data-transition="slide">\n                        ');
          if (category.hasThumbnail()) {
            __out.push('\n                            ');
            background_img = category.hasThumbnail();
            __out.push('\n                            <span class="link_image" style="background-image: url(\'');
            __out.push(background_img);
            __out.push('\')"></span>\n                        ');
          } else {
            __out.push('\n                            <span class="link_image"></span>\n                        ');
          }
          __out.push('\n                        <span class="link_word">');
          __out.push(gettext.gettext(name));
          __out.push('</span>\n                    </a>\n                </div>\n            ');
        }
        __out.push('\n        ');
      }
    
      __out.push('\n        </div>\n\n    </div>\n</div>\n');
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/categories/templates/category", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var prev;
    
      if (this.category.get('parent')) {
        __out.push('\n    ');
        prev = "#category/" + this.category.get('parent');
        __out.push('\n');
      } else {
        __out.push('\n    ');
        prev = "#categoryMenu";
        __out.push('\n');
      }
    
      __out.push('\n\n<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-home">\n            <a href="');
    
      __out.push(prev);
    
      __out.push('" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n    <h2>');
    
      __out.push(this.category.get('name'));
    
      __out.push('</h2>\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-bag">\n            <a href="#stats" id="userinfo_button" class="user_points">\n                <span class="label">\n                    <span class="point_name">');
    
      __out.push(gettext.gettext("Points"));
    
      __out.push('</span>\n                </span>\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content" id="category_content">\n    <div id="category_background">\n        <div id="category_buttons">\n            <ul class="aajege-buttons">\n\t            <li>\n\t            \t<a class="aajege-button"\n\t            \t   href="#conceptSet/');
    
      __out.push(this.category.get('category'));
    
      __out.push('" \n\t            \t   data-transition="slide">');
    
      __out.push(gettext.gettext("Wordlist"));
    
      __out.push('</a>\n\t            </li>\n\t            <li>\n\t                <a class="aajege-button"\n\t                   href="#leksa/1/');
    
      __out.push(this.category.get('category'));
    
      __out.push('" \n\t                   data-transition="slide">');
    
      __out.push(gettext.gettext("Learn"));
    
      __out.push('</a>\n\t            </li>\n\t            <li>\n\t                <a class="aajege-button"\n\t                   href="#leksa/2/');
    
      __out.push(this.category.get('category'));
    
      __out.push('" \n\t                   data-transition="slide">');
    
      __out.push(gettext.gettext("Practice"));
    
      __out.push('</a>\n\t           </li>\n            </ul>\n        </div>\n    </div>\n</div> \n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/categories/templates/subcategory", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var background_img, cat, category, group, label, name, _i, _j, _len, _len1, _ref, _ref1;
    
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-left-arrow">\n            <a href="#categoryMenu" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n    <h2> ');
    
      __out.push(gettext.gettext(this.category.get('name')));
    
      __out.push(' </h2>\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-bag">\n            <a href="#stats" id="userinfo_button" class="disable_auto_handler user_points">\n                <span class="label">\n                    <span class="point_name">');
    
      __out.push(gettext.gettext("Points"));
    
      __out.push('</span>\n                </span>\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content" id="subcategory_menu">\n    <div id="category_background">\n        <div class="category_buttons">\n            <div class="ui-grid-b">\n            ');
    
      _ref = this.subcategory;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        group = _ref[_i];
        __out.push('\n                ');
        for (_j = 0, _len1 = group.length; _j < _len1; _j++) {
          _ref1 = group[_j], category = _ref1[0], label = _ref1[1];
          __out.push('\n                    ');
          cat = category.get('category');
          __out.push('\n                    ');
          name = category.get('name');
          __out.push('\n\n                    <div class="ui-block-');
          __out.push(label);
          __out.push('">\n                        ');
          if (category.get('grayed_out')) {
            __out.push('\n                        <a class="square grayed"\n                        ');
          } else {
            __out.push('\n                        <a class="square"\n                        ');
          }
          __out.push('\n                           href="#category/');
          __out.push(cat);
          __out.push('"\n                           data-transition="slide">\n                            ');
          if (category.hasThumbnail()) {
            __out.push('\n                                ');
            background_img = category.hasThumbnail();
            __out.push('\n                                <span class="link_image" style="background-image: url(\'');
            __out.push(background_img);
            __out.push('\')"></span>\n                            ');
          } else {
            __out.push('\n                                <span class="link_image"></span>\n                            ');
          }
          __out.push('\n                            <span class="link_word">');
          __out.push(gettext.gettext(name));
          __out.push('</span>\n                        </a>\n                    </div>\n                ');
        }
        __out.push('\n            ');
      }
    
      __out.push('\n            </div>\n        </div>\n    </div>\n</div>\n\n');
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/concepts/list", function(exports, require, module) {
var ConceptItem, ConceptList, ConceptListTemplate, ConceptView, ConceptViewMain, _ref, _ref1,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ConceptItem = require('./templates/item');

ConceptListTemplate = require('./templates/list');

ConceptViewMain = require('./templates/concepts');

ConceptView = (function(_super) {
  __extends(ConceptView, _super);

  function ConceptView() {
    _ref = ConceptView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  ConceptView.prototype.play = function() {
    var _this = this;
    this.model.playAudio({
      begin: function() {
        return _this.$el.find('.audio_link').children('img').addClass('playing');
      },
      finished: function() {
        console.log("finished event");
        return $(document).find('.audio_link img').removeClass('playing');
      }
    });
    return false;
  };

  ConceptView.prototype.template = ConceptItem;

  ConceptView.prototype.render = function() {
    var a, compress, fallback, maxFontSize, minFontSize, success, translation_language, translations, txl_string;
    translation_language = app.options.getSetting('help_language');
    fallback = false;
    translations = this.model.getTranslationsToLang(translation_language);
    txl_string = ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = translations.length; _i < _len; _i++) {
        a = translations[_i];
        _results.push(a.get('concept_value'));
      }
      return _results;
    })()).join(', ');
    success = false;
    if (app.user) {
      success = this.model.successRateInUserLog();
    } else {
      if (app.userprogression.models.length > 0) {
        success = this.model.successRateInUserLog();
      }
    }
    this.$el.html(this.template({
      model: this.model,
      success_rate: success,
      cid: this.model.cid,
      concept_value: this.model.get('concept_value'),
      concept_type: this.model.get('concept_type'),
      translations: translations,
      txl_string: txl_string,
      fallback: fallback,
      userlang: translation_language,
      next: this.next,
      prev: this.prev
    }));
    if (app.device_type === 'tablet') {
      minFontSize = "20px";
      maxFontSize = "36px";
      compress = 1.5;
    }
    if (app.device_type === 'mobile') {
      minFontSize = "14px";
      maxFontSize = "22px";
      compress = 1;
    }
    this.play();
    return this;
  };

  return ConceptView;

})(Backbone.View);

module.exports = ConceptList = (function(_super) {
  __extends(ConceptList, _super);

  function ConceptList() {
    _ref1 = ConceptList.__super__.constructor.apply(this, arguments);
    return _ref1;
  }

  ConceptList.prototype.id = "concept_view";

  ConceptList.prototype.events = {
    'click .audio_link': 'findAudio',
    'click #show-panel': "revealWordsPanel",
    'click .concept_link': 'showConcept',
    'click #cycle-concept-prev': 'prevConcept',
    'click #cycle-concept-next': 'nextConcept',
    "click .aajege-header a": "clickSound"
  };

  ConceptList.prototype.clickSound = function(evt) {
    app.soundEffects.click();
    return true;
  };

  ConceptList.prototype.clickTest = function(evt) {
    $(evt.target).get;
    console.log(evt);
    return true;
  };

  ConceptList.prototype.nextConcept = function() {
    if (this.next != null) {
      this.conceptByIndex(this.next);
    }
    return false;
  };

  ConceptList.prototype.prevConcept = function() {
    if (this.prev != null) {
      this.conceptByIndex(this.prev);
    }
    return false;
  };

  ConceptList.prototype.conceptByIndex = function(concept_index) {
    var concept, concept_link, concept_list, concept_template, el_pos, link_li, new_position, next, prev;
    concept = this.concepts_in_order[concept_index];
    if (!concept) {
      return false;
    }
    prev = null;
    if ((concept_index - 1) > -1) {
      prev = concept_index - 1;
    }
    next = concept_index + 1;
    concept_template = new ConceptView({
      model: concept
    });
    this.current_concept_view = concept_template;
    this.prev = prev;
    this.next = next;
    $('#concept_content').html(concept_template.render().$el.html());
    $('#concept_content').trigger('create');
    concept_list = this.$el.find('#concept-list');
    concept_link = concept_list.find("[data-concept-index=" + concept_index + "]");
    concept_list.find('.ui-btn-active-d').removeClass('ui-btn-active-d');
    concept_link.parents('li.ui-btn').addClass('ui-btn-active-d');
    el_pos = concept_link.parents('li.ui-btn').position();
    link_li = concept_link.parents('li.ui-btn');
    new_position = concept_list.scrollTop(concept_list.scrollTop() + (link_li.position().top - concept_list.position().top) - (concept_list.height() / 2) + (link_li.height() / 2));
    return false;
  };

  ConceptList.prototype.showConcept = function(evt) {
    var concept, concept_index, concept_template, next, prev;
    concept_index = parseInt($(evt.target).attr('data-concept-index'));
    this.$el.find('.ui-btn-active-d').removeClass('ui-btn-active-d');
    $(evt.target).parents('li.ui-btn').addClass('ui-btn-active-d');
    concept = this.concepts_in_order[concept_index];
    prev = null;
    if ((concept_index - 1) > -1) {
      prev = concept_index - 1;
    }
    next = concept_index + 1;
    concept_template = new ConceptView({
      model: concept
    });
    this.current_concept_view = concept_template;
    this.prev = prev;
    this.next = next;
    $('#concept_content').html(concept_template.render().$el.html());
    $('#concept_content').trigger('create');
    $('#wordlist_panel').panel('close', {});
    return false;
  };

  ConceptList.prototype.findAudio = function(event) {
    var image,
      _this = this;
    image = $(document).find('.audio_link img');
    $(image).addClass('playing');
    this.current_concept_view.model.playAudio({
      begin: function() {
        return $(image).addClass('playing');
      },
      finished: function() {
        return image.removeClass('playing');
      }
    });
    return false;
  };

  ConceptList.prototype.className = 'conceptlist';

  ConceptList.prototype.template = ConceptListTemplate;

  ConceptList.prototype.calculateContentHeight = function() {
    var header_height, window_height;
    header_height = $('.aajege-header').outerHeight();
    window_height = $(window).height();
    this.$el.find('#concepts_content').css('height', "" + (window_height - header_height) + "px");
    return false;
  };

  ConceptList.prototype.render = function() {
    var category, category_concepts, getTxl, initial, sortTxl, translation_language,
      _this = this;
    translation_language = app.options.getSetting('help_language');
    category = _.first(app.categories.where({
      category: this.for_category
    }));
    category_concepts = category.getConcepts({
      language: 'sma'
    });
    this.next = 1;
    this.prev = null;
    getTxl = function(m) {
      var a, translations, txl_string;
      translations = m.getTranslationsToLang(translation_language);
      txl_string = _.uniq((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = translations.length; _i < _len; _i++) {
          a = translations[_i];
          _results.push(a.get('concept_value'));
        }
        return _results;
      })()).join(', ');
      return m.set('txl_string', txl_string);
    };
    sortTxl = function(m) {
      return m.get('txl_string');
    };
    category_concepts = category_concepts.map(getTxl);
    if (category.attributes.order_by == null) {
      category_concepts = _.sortBy(category_concepts, sortTxl);
    }
    this.concepts_in_order = category_concepts;
    initial = new ConceptView({
      model: category_concepts[0]
    });
    this.current_concept_view = initial;
    this.$el.html(this.template({
      category: category,
      models: this.concepts_in_order,
      initial_model: initial.render().$el.html()
    }));
    this.$el.find('ul#concept-list li:first').addClass('ui-btn-active-d');
    this.calculateContentHeight();
    return this;
  };

  return ConceptList;

})(Backbone.View);
});

;require.register("views/concepts/templates/concepts", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var t, _i, _len, _ref;
    
      __out.push('<div data-role="header">\n    <a href="/#wordlist" data-transition="slide" data-icon="arrow-l">');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('</a>\n    <h2> ');
    
      __out.push(this.model.get('concept_value'));
    
      __out.push(' </h2>\n</div> \n\n<div data-role="content" class="concept">\n    <div class="ui-grid-a">\n\t    <div class="ui-block-a">\n            ');
    
      if (this.model.hasImage()) {
        __out.push('\n                <img width="150" \n                     height="150" \n                     src="');
        __out.push(this.model.hasImage());
        __out.push('" />\n            ');
      }
    
      __out.push('\n        </div>\n\t    <div class="ui-block-b">\n            ');
    
      if (this.model.hasAudio()) {
        __out.push('\n                <a href="#" class="audio_link">\n                    <img width="32" height="32" src="/static/client/images/speaker.png" />\n                    Listen\n                </a>\n            ');
      }
    
      __out.push('\n            <ul class="translations">\n                ');
    
      _ref = this.translations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        t = _ref[_i];
        __out.push('\n                    <li>');
        __out.push(t.get('concept_value'));
        __out.push('</li>\n                ');
      }
    
      __out.push('\n            </ul>\n\t    </div>\t   \n    </div>\n\n</div> \n\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/concepts/templates/item", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var vid, _i, _len, _ref;
    
      if (this.model.hasImage({
        no_default: true
      })) {
        __out.push('\n    <div id="concept_img_frame">\n        <img id="current_concept_img"\n             style="background-image: url(');
        __out.push(this.model.hasImage());
        __out.push(')" />\n     </div>\n');
      } else if (this.model.hasVideo({
        no_default: true
      })) {
        __out.push('\n    ');
        if (app.video_format === 'gif') {
          __out.push('\n      <div id="concept_img_frame">\n          <img id="current_concept_img"\n               style="background-image: url(');
          __out.push(this.model.hasVideo().path);
          __out.push(')" />\n      </div>\n    ');
        } else {
          __out.push('\n      <div id="concept_video_frame">\n          <video \n              class="conceptVideo"\n              id="current_concept_video"\n              webkit-playsinline\n              poster preload="true"\n              loop>\n              ');
          _ref = this.model.hasVideo();
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            vid = _ref[_i];
            __out.push('\n                  <source\n                  src="');
            __out.push(vid.path);
            __out.push('"\n                  ');
            if (vid.path.search('mp4') > -1) {
              __out.push('\n                  type="video/mp4">\n                  ');
            } else if (vid.path.search('webm') > -1) {
              __out.push('\n                  type="video/webm">\n                  ');
            }
            __out.push('\n              ');
          }
          __out.push('\n              </video>\n       </div>\n    ');
        }
        __out.push('\n');
      } else {
        __out.push('\n    <div id="concept_img_frame">\n        <img id="current_concept_img"\n             style="background-image: url(/static/images/missing_concept_image.jpg)" />\n     </div>\n');
      }
    
      __out.push('\n\n<ul id="concept_definitions">\n    <li>\n        <h2 data-textfill class="concept_definition concept_value">\n            <span>');
    
      __out.push(this.model.get('concept_value'));
    
      __out.push('</span>\n        </h2>\n    </li>\n\n    <!--\n    ');
    
      if (this.fallback) {
        __out.push('\n        <li>\n             <h2 class="concept_definition">');
        __out.push(this.txl_string);
        __out.push(' <span class="concept_language">(');
        __out.push(tx.get('language'));
        __out.push(')</span></h2>\n        </li>\n    ');
      } else {
        __out.push('\n        <li>\n            <h2 class="concept_definition">');
        __out.push(this.txl_string);
        __out.push('</h2>\n        </li>\n    ');
      }
    
      __out.push('\n    -->\n\n</ul>\n\n\n<div id="nav_buttons">\n    ');
    
      if (this.model.hasAudio()) {
        __out.push('\n            <a href="#"\n               class="audio_link"\n               data-concept-cid="');
        __out.push(this.cid);
        __out.push('">\n                <img width="48"\n                     height="48"\n                     class="play_speaker"\n                     src="/static/client/images/speaker.png" />\n            </a>\n    ');
      }
    
      __out.push('\n</div>\n\n');
    
      if (this.fallback) {
        __out.push('\n    <span class="error">No definition in db for ');
        __out.push(this.userlang);
        __out.push(' for word, falling back to nob.</span>\n');
      }
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/concepts/templates/list", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var color, concept, i, _i, _len, _ref;
    
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-home">\n            <a href="#index" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Home"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n        <li class="icon-aajege-left-arrow">\n            <a href="#category/');
    
      __out.push(this.category.get('category'));
    
      __out.push('" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n\n    <h2>');
    
      __out.push(this.category.get('name'));
    
      __out.push('</h2>\n\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-bag">\n            <a href="#stats" id="userinfo_button" class="user_points">\n                <span class="label">\n                    <span class="point_name">');
    
      __out.push(gettext.gettext("Points"));
    
      __out.push('</span>\n                </span>\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content" id="concepts_content">\n    <div class="ui-grid-a twothirds" id="concept_content_block">\n        <div class="ui-block-a left-block" id="concept_content">\n            ');
    
      __out.push(this.initial_model);
    
      __out.push('\n        </div>\n        <div class="ui-block-b right-block">\n            <ul data-role="listview" \n                data-theme="i" \n                data-divider-theme="c" \n                data-split-icon=""\n                data-icon=""\n                id="concept_list"\n                class="ui-listview">\n                ');
    
      _ref = this.models;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        concept = _ref[i];
        __out.push('\n                    ');
        color = false;
        __out.push('\n                      \n                    ');
        if (i === 0) {
          __out.push('\n                    <li class=\'ui-btn-active-d\'>\n                    ');
        } else {
          __out.push('\n                    <li>\n                    ');
        }
        __out.push('\n                        <a class="concept_link"\n                           data-concept-index="');
        __out.push(i);
        __out.push('"\n                           href="#">');
        __out.push(concept.get('txl_string'));
        __out.push('</a>\n                    </li>\n                ');
      }
    
      __out.push('\n            </ul>\n            <div class="scroll-arrow">\n                <i class="icon-aajege-down-arrow" />\n            </div>\n        </div>\n    </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/error/templates/error", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<h3>Uh oh, an error occurred.</h3>\nError: ');
    
      __out.push(window.last_error);
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/error/view", function(exports, require, module) {
var ErrorTemplate, ErrorView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

ErrorTemplate = require('./templates/error');

module.exports = ErrorView = (function(_super) {
  __extends(ErrorView, _super);

  function ErrorView() {
    _ref = ErrorView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  ErrorView.prototype.className = 'error';

  ErrorView.prototype.id = "error";

  ErrorView.prototype.template = ErrorTemplate;

  ErrorView.prototype.render = function() {
    this.$el.html(this.template);
    return this;
  };

  return ErrorView;

})(Backbone.View);
});

;require.register("views/games/learn", function(exports, require, module) {
var LearnView, LeksaConceptTemplate, LeksaView, LevelCompleted, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LevelCompleted = require('./templates/leksa_level_completed');

LeksaConceptTemplate = require('/views/templates/leksa_concept');

LeksaView = require('/views/games/leksa');

module.exports = LearnView = (function(_super) {
  __extends(LearnView, _super);

  function LearnView() {
    _ref = LearnView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  LearnView.prototype.events = {
    'click #menu_next': "newQuestionSameGroup",
    'click .disable_auto_handler': "reset_auto_event"
  };

  LearnView.prototype.id = "leksa";

  LearnView.prototype.auto_advance = true;

  LearnView.prototype.level_constraint = function(question) {
    return question.get('level') === 1;
  };

  LearnView.prototype.reset_auto_event = function() {
    if (app.wait_handler != null) {
      clearTimeout(app.wait_handler);
    }
    if (app.leksaView.auto_advance_handler != null) {
      clearInterval(this.auto_advance_handler);
    }
    if (app.leksaView.countdown_handle != null) {
      clearInterval(this.countdown_handle);
    }
    return true;
  };

  LearnView.prototype.selectQuestionForRendering = function() {
    var level_constraint, q;
    if (app.questiondb.length === 0 && app.conceptdb.length === 0) {
      window.last_error = "Question DB and Concept DB not ready.";
      app.router.navigate('error');
    }
    if (this.attributes.level_constraint) {
      level_constraint = this.level_constraint;
    } else {
      level_constraint = function(level) {
        return true;
      };
    }
    if (this.ordering != null) {
      q = app.questiondb.selectQuestion(this.attributes.leksa_category, false, this.ordering);
    } else {
      q = app.questiondb.selectQuestionByProg(this.attributes.leksa_category, level_constraint);
    }
    return q;
  };

  LearnView.prototype.renderQuestion = function() {
    var DummyConcept, c, concepts, last, playFirst, _err_msg, _log_msg, _ref1,
      _this = this;
    $('.set_done_options').hide();
    window.scrollTo(0, 0);
    if (this.preselected_q != null) {
      if (app.debug) {
        console.log("Pregenerated for click event.");
      }
      this.q = this.preselected_q;
      delete this.preselected_q;
    } else {
      this.q = this.selectQuestionForRendering();
    }
    if (this.ordering == null) {
      if (app.debug) {
        console.log("choosing ordering");
      }
      this.cat = _.first(app.categories.where({
        category: this.attributes.leksa_category
      }));
      concepts = this.cat.getConcepts({
        language: this.q.generator.attributes.filters.to_language
      });
      this.ordering = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = concepts.length; _i < _len; _i++) {
          c = concepts[_i];
          _results.push(c.get('concept_value'));
        }
        return _results;
      })();
      this.ordering = _.shuffle(this.ordering.filter(function(c) {
        return c !== _this.q.answer.attributes.concept_value;
      }));
      this.ordering.push(this.q.answer.attributes.concept_value);
    } else {
      last = this.ordering.shift(0);
      this.ordering.push(last);
    }
    if (app.debug) {
      console.log(this.ordering);
    }
    if (!this.q.question) {
      _log_msg = "LearnView.render_question: ungeneratable question in ordering";
      _log_msg += " " + this.ordering.join(', ');
      console.log(this.ordering);
      window.client_log.error(_log_msg);
      _err_msg = "A question could not be generated from these parameters";
      this.$el.find('#leksa_question').html(this.leksa_error_template({
        error_msg: _err_msg
      }));
      return false;
    }
    DummyConcept = (function(_super1) {
      __extends(DummyConcept, _super1);

      function DummyConcept() {
        _ref1 = DummyConcept.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      DummyConcept.prototype.render_concept = function() {
        return LeksaConceptTemplate({
          concept: this,
          concept_type: this.get('concept_type'),
          concept_value: this.get('concept_value'),
          additional_class: "no_frame"
        });
      };

      return DummyConcept;

    })(Backbone.Model);
    if (this.q.choices.length === 3 && this.q.generator.get('type') === "word_to_image") {
      this.q.choices.push(new DummyConcept({
        concept_value: "/static/images/bakgrunn-spill.png",
        concept_type: "img"
      }));
      this.q.choices = _.shuffle(this.q.choices);
    }
    this.$el.find('#leksa_question').html(this.question_template({
      instance: this.q,
      chunker: arrayChunk,
      audio: this.q.question.hasAudio(),
      q_type: this.q.generator.get('type')
    }));
    this.$el.find('#leksa_question a.answerlink.text').textfill({
      minFontPixels: 18,
      maxFontPixels: 36
    });
    this.$el.find('#leksa_question a.answerlink').click(function(evt) {
      return false;
    });
    app.router.refreshCurrentPage();
    playFirst = function() {
      if (app.options.getSetting('enable_audio') && _this.q.generator.get('sound')) {
        return _this.playQuestionSound();
      }
    };
    if (this.pregenerated != null) {
      delete this.pregenerated;
    } else {
      if (!this.first) {
        app.wait_handler = setTimeout(playFirst, 1500);
        this.first = false;
      } else {
        playFirst();
      }
    }
    this.$el.find('#question_play').click(function() {
      if (app.debug != null) {
        console.log("Play:");
        console.log(_this.q.question);
      }
      _this.q.question.playAudio();
      return false;
    });
    return true;
  };

  LearnView.prototype.playQuestionSound = function() {
    var a, checkPosition;
    if (this.preselected_q) {
      a = this.preselected_q;
    } else {
      a = this.q;
    }
    window.current_audio = a.question.playAudio();
    checkPosition = function() {
      var current_audio;
      current_audio = window.current_audio;
      if (current_audio.position === current_audio.duration || current_audio.position === current_audio.durationEstimate) {
        return app.leksaView.soundFinished();
      } else {
        return setTimeout(checkPosition, 200);
      }
    };
    if (typeof current_audio !== "undefined" && current_audio !== null) {
      return setTimeout(checkPosition, 200);
    } else {
      return app.leksaView.soundFinished();
    }
  };

  LearnView.prototype.soundFinished = function() {
    var _this = this;
    if (app.debug) {
      console.log("View got sound finished.");
    }
    return app.wait_handler = setTimeout(function() {
      if (/leksa/.exec(window.location.hash)) {
        return app.leksaView.renderQuestion();
      } else {
        clearTimeout(app.wait_handler);
        return false;
      }
    }, 4000);
  };

  LearnView.prototype.render = function() {
    this.cat = _.first(app.categories.where({
      category: this.attributes.leksa_category
    }));
    this.$el.html(this.template({
      leksa_category: this.attributes.leksa_category,
      category: this.cat.attributes.name
    }));
    this.pts_bubble = this.$el.find('#points_for_question');
    this.pts_bubble.hide();
    app.leksaView.renderQuestion();
    this.first = true;
    return this;
  };

  return LearnView;

})(LeksaView);
});

;require.register("views/games/leksa", function(exports, require, module) {
var LeksaConceptTemplate, LeksaErrorTemplate, LeksaQuestionImageToWord, LeksaQuestionWordToImage, LeksaQuestionWordToWord, LeksaTemplate, LeksaView, StatTemplate, UserLog, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

UserLog = require('models/user_log_entry');

LeksaTemplate = require('./templates/leksa');

LeksaErrorTemplate = require('./templates/leksa_error_template');

LeksaQuestionImageToWord = require('./templates/leksa_question_image_to_word');

LeksaQuestionWordToWord = require('./templates/leksa_question_image_to_word');

LeksaQuestionWordToImage = require('./templates/leksa_question_word_to_image');

StatTemplate = require('./templates/stat_block');

LeksaConceptTemplate = require('/views/templates/leksa_concept');

module.exports = LeksaView = (function(_super) {
  __extends(LeksaView, _super);

  function LeksaView() {
    this.level_constraint = __bind(this.level_constraint, this);
    _ref = LeksaView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  LeksaView.prototype.id = "leksa";

  LeksaView.prototype.template = LeksaTemplate;

  LeksaView.prototype.auto_advance = false;

  LeksaView.prototype.level_constraint = function(question) {
    return question.get('level') >= this.attributes.level_constraint;
  };

  LeksaView.prototype.question_template = function(context) {
    var tpl;
    tpl = (function() {
      switch (context.q_type) {
        case "image_to_word":
          return LeksaQuestionImageToWord;
        case "word_to_word":
          return LeksaQuestionWordToWord;
        case "word_to_image":
          return LeksaQuestionWordToImage;
      }
    })();
    return tpl(context);
  };

  LeksaView.prototype.leksa_error_template = LeksaErrorTemplate;

  LeksaView.prototype.events = {
    'click #menu_next': "newQuestionSameGroup",
    'click .disable_auto_handler': "reset_auto_event"
  };

  LeksaView.prototype.reset_auto_event = function() {
    clearInterval(this.auto_advance_handler);
    clearInterval(this.countdown_handle);
    return true;
  };

  LeksaView.prototype.newQuestionSameGroup = function(evt) {
    this.renderQuestion();
    return false;
  };

  LeksaView.prototype.correctAnswer = function(q, user_input) {
    var answer_offset, correct_answer_concept, height_offset, user_answer_concept, width_offset,
      _this = this;
    if (app.wait_handler != null) {
      clearInterval(app.wait_handler);
      this.answer_in = true;
    }
    user_answer_concept = q.answer;
    correct_answer_concept = q.question;
    answer_offset = $(user_input).offset();
    width_offset = ($(user_input).width() / 2) - (this.pts_bubble.width() / 2);
    height_offset = this.pts_bubble.height() / 2;
    $(user_input).addClass('correct');
    this.logConcept(q.generator, correct_answer_concept, true);
    $('.set_done_options').show();
    setTimeout((function() {
      return _this.$el.find('#menu_next').click();
    }), 1200);
    clearInterval(app.wait_handler);
    this.pts_bubble.css('top', "" + (answer_offset.top - height_offset) + "px");
    this.pts_bubble.css('left', "" + (answer_offset.left + width_offset) + "px");
    this.pts_bubble.fadeIn(100);
    return false;
  };

  LeksaView.prototype.logConcept = function(question_generator, concept, correct) {
    var concept_name, log, points_given, _lang_to_filt, _to, _transl,
      _this = this;
    concept_name = concept.get('concept_value');
    if (concept.get('concept_type') === 'img') {
      _to = question_generator.get('filters').to_language;
      _lang_to_filt = function(c) {
        return c.get('language') === _to;
      };
      _transl = app.conceptdb.getTranslationsOf(concept).filter(_lang_to_filt);
      if (_transl.length > 0) {
        concept_name = _transl[0].get('concept_value');
      }
    }
    if (correct) {
      points_given = this.cur_points;
      if (points_given < 0) {
        points_given = 0;
      }
    } else {
      points_given = 0;
    }
    log = app.userprogression.logActivity({
      game_name: "leksa",
      question_concept: concept.get('concept_value'),
      question_concept_value: concept_name,
      question_correct: correct,
      question_category: question_generator.get('category'),
      question_category_level: question_generator.get('level'),
      points: points_given,
      cycle: question_generator.get('cycle')
    });
    return true;
  };

  LeksaView.prototype.incorrectAnswer = function(q, user_input) {
    var correct_answer_concept, user_answer_concept;
    if (this.cur_points > 10) {
      this.cur_points -= 10;
    }
    user_answer_concept = q.answer;
    correct_answer_concept = q.question;
    $(user_input).addClass('incorrect');
    this.logConcept(q.generator, correct_answer_concept, false);
    return false;
  };

  LeksaView.prototype.levelComplete = function() {
    return false;
  };

  LeksaView.prototype.selectQuestionForRendering = function() {
    var level_constraint, q;
    if (app.questiondb.length === 0 && app.conceptdb.length === 0) {
      window.last_error = "Question DB and Concept DB not ready.";
      app.router.navigate('error');
    }
    if (this.attributes.level_constraint) {
      level_constraint = this.level_constraint;
    } else {
      level_constraint = function(level) {
        return true;
      };
    }
    q = app.questiondb.selectQuestionByProg(this.attributes.leksa_category, level_constraint);
    return q;
  };

  LeksaView.prototype.displayUserPoints = function() {
    var count;
    count = app.userprogression.countPoints();
    this.$el.find('#point_total').html(count);
  };

  LeksaView.prototype.renderQuestion = function() {
    var DummyConcept, level_note, playFirst, _err_msg, _log_msg, _ref1, _repeats,
      _this = this;
    $('.set_done_options').hide();
    this.answer_in = false;
    if (app.wait_handler != null) {
      clearInterval(app.wait_handler);
    }
    window.scrollTo(0, 0);
    this.displayUserPoints();
    if (this.preselected_q != null) {
      if (app.debug) {
        console.log("Pregenerated for click event.");
      }
      this.q = this.preselected_q;
      delete this.preselected_q;
    } else {
      this.q = this.selectQuestionForRendering();
    }
    if (this.q === false) {
      window.last_category = window.location.hash;
      window.location.hash = '#category_complete';
      return false;
    }
    if (this.last_level) {
      if (this.q.generator.get('level') !== this.last_level) {
        window.last_category = window.location.hash;
        window.location.hash = '#level_complete';
        this.last_level = false;
        return false;
      }
    }
    level_note = "Level " + (this.q.generator.get('level'));
    this.last_level = this.q.generator.get('level');
    _repeats = this.q.generator.get('repetitions');
    if (_repeats === 0) {
      _repeats = 1;
    } else {
      _repeats += 1;
    }
    if (!this.q.question) {
      _log_msg = "LeksaView.render_question: ungeneratable question - ";
      _log_msg += "" + (q.generator.get('category')) + "/" + (q.generator.get('level'));
      window.client_log.error(_log_msg);
      _err_msg = "A question could not be generated from these parameters";
      this.$el.find('#leksa_question').html(this.leksa_error_template({
        error_msg: _err_msg
      }));
      return false;
    }
    DummyConcept = (function(_super1) {
      __extends(DummyConcept, _super1);

      function DummyConcept() {
        _ref1 = DummyConcept.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      DummyConcept.prototype.render_concept = function() {
        return LeksaConceptTemplate({
          concept: this,
          concept_type: this.get('concept_type'),
          concept_value: this.get('concept_value'),
          additional_class: "no_frame"
        });
      };

      return DummyConcept;

    })(Backbone.Model);
    if (this.q.choices.length === 3 && this.q.generator.get('type') === "word_to_image") {
      this.q.choices.push(new DummyConcept({
        concept_value: "/static/images/bakgrunn-spill.png",
        concept_type: "img"
      }));
      this.q.choices = _.shuffle(this.q.choices);
    }
    this.$el.find('#leksa_question').html(this.question_template({
      instance: this.q,
      chunker: arrayChunk,
      audio: this.q.question.hasAudio(),
      q_type: this.q.generator.get('type')
    }));
    this.$el.find('#leksa_question a.answerlink.text').textfill({
      minFontPixels: 18,
      maxFontPixels: 36
    });
    this.cur_points = this.q.generator.get('points');
    this.pts_bubble.find('.points').html("+" + this.cur_points);
    this.pts_bubble.hide();
    this.$el.find('#leksa_question a.answerlink').click(function(evt) {
      var answer_value, answerlink, user_input;
      if (_this.auto_advance) {
        return false;
      } else {
        answerlink = $(evt.target).parents('.answerlink');
        user_input = answerlink.attr('data-word');
        answer_value = _this.q.answer.get('concept_value');
        window.last_user_input = answerlink;
        if (user_input === answer_value) {
          _this.$el.find('#leksa_question a.answerlink').unbind('click').click(function(evt) {
            return false;
          });
          _this.correctAnswer(_this.q, answerlink);
        } else {
          _this.incorrectAnswer(_this.q, answerlink);
        }
        answerlink.unbind('click').click(function(evt) {
          return false;
        });
        return false;
      }
    });
    app.router.refreshCurrentPage();
    playFirst = function() {
      var speaker;
      if (app.options.getSetting('enable_audio') && _this.q.generator.get('sound')) {
        speaker = $(document).find('img.play_speaker');
        speaker.addClass('playing');
        return _this.playQuestionSound();
      }
    };
    if (this.pregenerated != null) {
      delete this.pregenerated;
    } else {
      if (!this.first) {
        setTimeout(playFirst, 1500);
        this.first = false;
      } else {
        playFirst();
      }
    }
    this.$el.find('#question_play').click(function() {
      var speaker;
      if (app.debug != null) {
        console.log("Play:");
        console.log(_this.q.question);
      }
      speaker = $(document).find('img.play_speaker').addClass('playing');
      _this.q.question.playAudio();
      return false;
    });
    return true;
  };

  LeksaView.prototype.playQuestionSound = function() {
    var a;
    if (this.preselected_q) {
      a = this.preselected_q;
    } else {
      a = this.q;
    }
    return this.current_audio = a.question.playAudio({
      finished: app.leksaView.soundFinished
    });
  };

  LeksaView.prototype.countdownPoints = function() {
    if (app.leksaView.cur_points > 5) {
      app.leksaView.cur_points -= 5;
      app.leksaView.pts_bubble.find('.points').html("+" + app.leksaView.cur_points);
      if (app.debug) {
        console.log("available points: " + app.leksaView.cur_points);
      }
    }
    app.wait_handler = setTimeout(app.leksaView.countdownPoints, 1000);
    return false;
  };

  LeksaView.prototype.soundFinished = function() {
    var speaker;
    speaker = $(document).find('img.play_speaker').removeClass('playing');
    if (app.debug) {
      console.log("View got sound finished.");
      if (app.leksaView.answer_in) {
        console.log("Sound finished, but user answered first.");
      }
    }
    if (!app.leksaView.answer_in) {
      app.leksaView.countdownPoints();
    }
    return false;
  };

  LeksaView.prototype.render = function() {
    if (app.wait_handler != null) {
      console.log("Clearing old wait handler");
      clearTimeout(app.wait_handler);
    }
    this.last_level = false;
    this.cat = _.first(app.categories.where({
      category: this.attributes.leksa_category
    }));
    this.$el.html(this.template({
      leksa_category: this.attributes.leksa_category,
      category: this.cat.attributes.name
    }));
    this.pts_bubble = this.$el.find('#points_for_question');
    this.pts_bubble.hide();
    this.renderQuestion();
    this.first = true;
    return this;
  };

  return LeksaView;

})(Backbone.View);
});

;require.register("views/games/leksa_options_view", function(exports, require, module) {
var LeksaOptionsView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = LeksaOptionsView = (function(_super) {
  __extends(LeksaOptionsView, _super);

  function LeksaOptionsView() {
    _ref = LeksaOptionsView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  LeksaOptionsView.prototype.className = 'hello';

  LeksaOptionsView.prototype.events = {
    'click #save-options': 'saveOptions'
  };

  LeksaOptionsView.prototype.getLevel = function() {
    var _level;
    _level = this.$el.find('#current_level input[checked]').val();
    if (_level.length === 0) {
      _level = false;
    }
    return _level;
  };

  LeksaOptionsView.prototype.getSet = function() {
    var _set;
    _set = this.$el.find('#semantic_set input[checked]').val();
    if (_set.length === 0) {
      _set = false;
    }
    return _set;
  };

  LeksaOptionsView.prototype.saveOptions = function(evt) {
    var toBool, _level, _set;
    toBool = function(v) {
      switch (v) {
        case "true":
          return true;
        case "false":
          return false;
      }
    };
    _level = this.getLevel();
    _set = this.getSet();
    if (_level) {
      app.leksaOptions.current_level = _level;
    }
    if (_set) {
      return app.leksaOptions.current_set = _set;
    }
  };

  LeksaOptionsView.prototype.template = require('./templates/leksa_options_view');

  LeksaOptionsView.prototype.render = function() {
    var _level, _set;
    this.$el.html(this.template);
    _level = this.getLevel();
    _set = this.getSet();
    if (_level) {
      this.$el.find("#current_level input[value='" + _level + "'").click();
    }
    if (_set) {
      this.$el.find("#semantic_set input[value='" + _set + "'").click();
    }
    return this;
  };

  return LeksaOptionsView;

})(Backbone.View);
});

;require.register("views/games/level_complete", function(exports, require, module) {
var LevelComplete, LevelCompleteTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LevelCompleteTemplate = require('./templates/leksa_level_completed');

module.exports = LevelComplete = (function(_super) {
  __extends(LevelComplete, _super);

  function LevelComplete() {
    _ref = LevelComplete.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  LevelComplete.prototype.id = "level_complete";

  LevelComplete.prototype.events = {
    'click a#repeat': 'navigateBack'
  };

  LevelComplete.prototype.template = LevelCompleteTemplate;

  LevelComplete.prototype.navigateBack = function(e) {
    e.preventDefault();
    window.location.hash = window.last_category;
    return delete window.last_category;
  };

  LevelComplete.prototype.render = function() {
    this.$el.html(this.template({
      category: this.category
    }));
    setTimeout(app.soundEffects.correct, 500);
    return this;
  };

  return LevelComplete;

})(Backbone.View);
});

;require.register("views/games/templates/leksa", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-home">\n            <a href="#index" data-transition="slide" class="disable_auto_handler">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Home"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n        <li class="icon-aajege-left-arrow">\n            <a href="#category/');
    
      __out.push(this.leksa_category);
    
      __out.push('" class="disable_auto_handler">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n    <h2>');
    
      __out.push(this.category);
    
      __out.push('</h2>\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-bag">\n            <a href="#stats" id="userinfo_button" class="disable_auto_handler user_points">\n                <span class="label">\n                    <span id="point_total"></span>\n                </span>\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content">\n\n    <div id="leksa_question">\n        ');
    
      if (this.leksa_question) {
        __out.push(this.leksa_question);
      }
    
      __out.push('\n    </div>\n\n    <div id="points_for_question"><span class="points">+15</span></div>\n\n    <div id="progress_container">\n        <div id="leksa_progress_indiv"><div class="progress_label"></div></div>\n    </div>\n\n</div>\n\n<a style="display: none;" data-role="button" id="menu_next" href="#" data-icon="arrow-r">Next</a>\n');
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/leksa_error_template", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<h3>Uh oh, an error occurred.</h3>\nError: ');
    
      __out.push(this.error_msg);
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/leksa_level_completed", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-home">\n            <a href="#index" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Home"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n\n    <h2>&nbsp;</h2>\n\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-bag">\n            <a href="#stats" id="userinfo_button" class="user_points">\n                <span class="label">\n                    <span class="point_name">');
    
      __out.push(gettext.gettext("Points"));
    
      __out.push('</span>\n                </span>\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content">\n    <div id="full_box">\n        <h1 class="tjoho">');
    
      __out.push(gettext.gettext("Tjoho!"));
    
      __out.push('</h1>\n        <h1 class="center-icon icon-is-too-big">\n            <span class="fa-stack fa-lg">\n              <i class="fa fa-circle fa-stack-2x"></i>\n              <i class="fa fa-star fa-stack-1x fa-inverse"></i>\n            </span>\n        </h1>\n    </div>\n    ');
    
      if (this.category) {
        __out.push('\n        <p class="note">');
        __out.push(gettext.gettext("You completed the category!"));
        __out.push('</p>\n    ');
      } else {
        __out.push('\n        <p class="note">');
        __out.push(gettext.gettext("You completed the level!"));
        __out.push('</p>\n    ');
      }
    
      __out.push('\n    ');
    
      if (this.category) {
        __out.push('\n    <a href="#" data-role="button" data-theme="b" id="repeat" data-mini="true">\n        ');
        __out.push(gettext.gettext("Play again"));
        __out.push(' <i class="fa fa-arrow-circle-right"></i>\n    </a>\n    ');
      } else {
        __out.push('\n    <a href="#" data-role="button" data-theme="b" id="repeat" data-mini="true">\n        ');
        __out.push(gettext.gettext("Next level"));
        __out.push(' <i class="fa fa-arrow-circle-right"></i>\n    </a>\n    ');
      }
    
      __out.push('\n    <br />\n    <a href="#categoryMenu" data-role="button" data-theme="b" id="back_to_categories" data-mini="true">\n        <i class="fa fa-arrow-circle-left"></i> ');
    
      __out.push(gettext.gettext("Category list"));
    
      __out.push('\n    </a>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/leksa_options_view", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div data-role="header">\n    <a href="#leksa" data-transition="slide" data-icon="arrow-l">');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('</a>\n    <h2>Options</h2>\n    <a id="save-options" data-icon="gear">Save</a>\n</div> \n\n<div data-role="content">\n    <h2>Game settings</h2>\n\n    <p>NB: currently only for testing. We\'ll put real options in later.</p>\n    <form id="option_form">\n\n    <div data-role="fieldcontain" id="semantic_set">\n        <fieldset data-role="controlgroup">\n            <legend>Set</legend>\n            <input type="radio" name="radio-choice-1" id="radio-choice-1" value="face" checked="checked">\n            <label for="radio-choice-1">Face</label>\n            <input type="radio" name="radio-choice-1" id="radio-choice-2" value="other">\n            <label for="radio-choice-2">Other</label>\n        </fieldset>\n    </div>\n\n    <div data-role="fieldcontain" id="current_level">\n        <fieldset data-role="controlgroup" data-type="horizontal" data-mini="true">\n            <legend>Level</legend>\n                <input type="radio" name="radio-choice-b" id="radio-choice-c" value="1">\n                <label for="radio-choice-c">1</label>\n                <input type="radio" name="radio-choice-b" id="radio-choice-d" value="2">\n                <label for="radio-choice-d">2</label>\n                <input type="radio" name="radio-choice-b" id="radio-choice-e" value="3">\n                <label for="radio-choice-e">3</label>\n                <input type="radio" name="radio-choice-b" id="radio-choice-f" value="4">\n                <label for="radio-choice-f">4</label>\n                <input type="radio" name="radio-choice-b" id="radio-choice-g" value="" checked="checked">\n                <label for="radio-choice-g">Auto</label>\n        </fieldset>\n    </div>\n\n    </form>\n</div> \n\n\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/leksa_question_image_to_word", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var choice, idx, _i, _len, _ref;
    
      __out.push('<div class="one_image">\n    <div class="question_prompt">\n        ');
    
      __out.push(this.instance.question.render_concept());
    
      __out.push('\n    </div>\n\n    <br />\n\n    <div class="possible_answers word_set">\n        ');
    
      _ref = this.instance.choices;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        choice = _ref[idx];
        __out.push('\n            <a class="answerlink text"\n               data-word="');
        __out.push(choice.get('concept_value'));
        __out.push('"\n               href="#">');
        __out.push(choice.render_concept());
        __out.push('</a>\n        ');
      }
    
      __out.push('\n    </div>\n\n    ');
    
      if (this.audio && this.instance.generator.get('sound')) {
        __out.push('\n        <a href="#" id="question_play"><img width="32" height="32" src="/static/client/images/speaker.png" class="play_speaker"/></a>\n    ');
      }
    
      __out.push('\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/leksa_question_word_to_image", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var chars, choice, choice_group, grid_count, idx, _i, _j, _len, _len1, _ref;
    
      __out.push('<div class="word_to_image">\n    <div class="possible_answers image_set">\n        <div class="image-grid-group grid-total-');
    
      __out.push(this.instance.choices.length);
    
      __out.push('">\n            ');
    
      _ref = this.chunker(this.instance.choices, 2);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        choice_group = _ref[_i];
        __out.push('\n                ');
        grid_count = 'grid-' + choice_group.length;
        __out.push('\n                <ul class="image-grid ');
        __out.push(grid_count);
        __out.push('">\n                ');
        chars = 'abcdefghijklmnopqrstuvwxyz';
        __out.push('\n                ');
        for (idx = _j = 0, _len1 = choice_group.length; _j < _len1; idx = ++_j) {
          choice = choice_group[idx];
          __out.push('\n                    <li class="image-item image-');
          __out.push(chars.charAt(idx));
          __out.push('">\n                        <a class="answerlink" data-word="');
          __out.push(choice.get('concept_value'));
          __out.push('" href="#"><span class="tint">');
          __out.push(choice.render_concept());
          __out.push('</span></a>\n                    </li>\n                ');
        }
        __out.push('\n                </ul>\n            ');
      }
    
      __out.push('\n        </div>\n    </div>\n\n    <div class="question_prompt">\n        ');
    
      __out.push(this.instance.question.render_concept());
    
      __out.push('\n    </div>\n\n    ');
    
      if (this.audio && this.instance.generator.get('sound')) {
        __out.push('\n        <a href="#" id="question_play"><img src="/static/client/images/speaker.png" class="play_speaker" /></a>\n    ');
      }
    
      __out.push('\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/games/templates/stat_block", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var concept, total_correct, _ref;
    
      __out.push('<h4>Overall progress</h4>\n<dl>\n<dt>Total points</dt>\n<dd>');
    
      __out.push(this.total_points);
    
      __out.push('</dd>\n<dt>Correct</dt>\n<dd>');
    
      __out.push(this.correct);
    
      __out.push('</dd>\n<dt>Total</dt>\n<dd>');
    
      __out.push(this.total);
    
      __out.push('</dk>\n</dl>\n<h4>Concept progress</h4>\n<h5>(Correct / tries)</h5>\n<dl>\n    ');
    
      _ref = this.concept_progress;
      for (concept in _ref) {
        total_correct = _ref[concept];
        __out.push('\n      <dt>');
        __out.push(concept);
        __out.push('</dt>\n      <dd>');
        __out.push(total_correct[0]);
        __out.push('/');
        __out.push(total_correct[1]);
        __out.push('</dd>\n    ');
      }
    
      __out.push('\n</dl>\n\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/info/info", function(exports, require, module) {
var InfoPage, InfoTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

InfoTemplate = require('./templates/info');

module.exports = InfoPage = (function(_super) {
  __extends(InfoPage, _super);

  function InfoPage() {
    _ref = InfoPage.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  InfoPage.prototype.id = "infoPage";

  InfoPage.prototype.template = InfoTemplate;

  InfoPage.prototype.render = function() {
    this.$el.html(this.template);
    return this;
  };

  return InfoPage;

})(Backbone.View);
});

;require.register("views/info/templates/info", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-left-arrow">\n            <a href="#index">\n            </a>\n        </li>\n    </ul>\n   <h2>');
    
      __out.push(gettext.gettext("About this app"));
    
      __out.push('</h2>\n   <hr class="aajege-flette" />\n</div>\n\n<div data-role="content" id="info_text_content">\n\n    <h3>Formål</h3>\n\n    <p> Hovedmålet med prosjektet er å fremme sørsamisk språkbruk på flere og nye\n    arenaer, samt utvikle hjelpemidler som bidrar i prosessen med vitalisering av\n    sørsamisk språk.  </p>\n\n    <h3> Resultatmål </h3>\n\n    <ul>\n        <li>Utvikle en sørsamisk språkapplikasjon for iPhone og iPad som\n        kombinerer sørsamisk lyd, skrift og bilde. </li>\n        <li>Bruke ny teknologi til å fremme bruk av sørsamisk\n        hverdagsspråk.</li>\n        <li>Synliggjøre sørsamisk på nye språkarenaer. </li>\n    </ul>\n\n    <h3> Målgruppe </h3>\n    <p>Den primære målgruppen er barn, ungdom og voksne som ønsker å lære,\n    repetere og/eller videreutvikle sine sørsamiske språkferdigheter.\n    Språknivået for brukeren vil kunne variere fra de som har liten kunnskap om\n    sørsamisk til de som kan snakke.</p> <p>Verktøyet kan brukes selvstendig av\n    enkeltpersoner, eller integreres som et hjelpemiddel i eksisterende\n    språkopplæring eller språkstimulering. Hjelpemidlet vil kunne være aktuelt\n    for alle som ønsker å arbeide med det sørsamiske språket.</p>\n\n    <h3> Medarbeidere </h3>\n    <dl>\n        <dt>Planlegging</dt>\n        <dd>Sissel Jåma, Helen Blind Brandsfjell, Toini Bergstrøm, Sjur Moshagen</dd>\n        <dt>Tekst</dt>\n        <dd>Sissel Jåma, Aino Danielsen, Helen Blind Brandsfjell</dd>\n        <dt>Foto</dt>\n        <dd>Vg2 Medier og kommunikasjon ved Røros videregående skole 2012/2013, Bente Haarstad, Aino Danielsen</dd>\n        <dt>Lyd</dt>\n        <dd>Peder Kristian Bientie Aasvold, Emmi Danielsen, Aino Danielsen</dd>\n        <dt>Illustrasjoner og layout</dt>\n        <dd>Anne Rustad</dd>\n        <dt>Programmerer</dt>\n        <dd>Ryan Johnson</dd>\n    </dl>\n\n    <p> Appen er produsert med støtte fra Sametinget, Fornyings-, administrasjons-\n    og kirkedepartementet og Aajege – samisk språk- og\n    kompetansesenter, Divvun-gruppa ved Universitetet i Tromsø </p>\n\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/intro/loading", function(exports, require, module) {
var LoadingView, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = LoadingView = (function(_super) {
  __extends(LoadingView, _super);

  function LoadingView() {
    _ref = LoadingView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  LoadingView.prototype.className = 'loading';

  LoadingView.prototype.id = "loading";

  LoadingView.prototype.template = require('./templates/loading');

  LoadingView.prototype.render = function() {
    var i;
    this.$el.html(this.template);
    app.loadingTracker.showLoading();
    i = 0;
    console.log("int " + i);
    this.$el.find("pre").html("Concepts:  " + app.conceptdb.models.length + "\nQuestions: " + app.questiondb.models.length);
    return this;
  };

  return LoadingView;

})(Backbone.View);
});

;require.register("views/intro/templates/front_page", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var disp;
    
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-right">\n        <li class="icon-aajege-info">\n            <a href="#infoPage">\n            </a>\n        </li>\n    </ul>\n    <hr class="aajege-flette" />\n</div>\n<div data-role="content" id="front_page_content">\n    <div class="ui-grid-a">\n        <div class="ui-block-a">\n            <h2 class="legend">');
    
      __out.push(gettext.gettext("Use an account?"));
    
      __out.push('</h2>\n        </div>\n        <div class="ui-block-b">\n            <h2 id="create_account_or_login_legend" class="legend">');
    
      __out.push(gettext.gettext("New account?"));
    
      __out.push('</h2>\n        </div>\n        <div class="ui-block-a">\n            <div data-role="fieldcontain" id="create_account">\n                <fieldset data-role="controlgroup" data-type="horizontal" data-setting="use_account">\n\n                    <input data-theme="a" \n                           type="radio" \n                           name="create-user-account" \n                           id="create-user-account-a" \n                           value="true" \n                           data-subquestion="user_account_block" checked>\n                    <label for="create-user-account-a">');
    
      __out.push(gettext.gettext("Yes"));
    
      __out.push('</label>\n\n                    <input data-theme="a" \n                           type="radio" \n                           name="create-user-account" \n                           id="create-user-account-b" \n                           value="false" \n                           data-hide-subquestion="user_account_block">\n                    <label for="create-user-account-b">');
    
      __out.push(gettext.gettext("No"));
    
      __out.push('</label>\n\n                </fieldset>\n            </div>\n        </div>\n\n        <div class="ui-block-b">\n            <div data-role="fieldcontain" id="create_account_or_login">\n                <fieldset data-role="controlgroup" data-type="horizontal" data-setting="use_account">\n\n                    <input data-theme="a" \n                           type="radio" \n                           name="login-or-new" \n                           id="login-or-new-a" \n                           value="true" \n                           checked>\n                    <label for="login-or-new-a">');
    
      __out.push(gettext.gettext("Yes"));
    
      __out.push('</label>\n\n                    <input data-theme="a" \n                           type="radio" \n                           name="login-or-new" \n                           id="login-or-new-b" \n                           value="false">\n                    <label for="login-or-new-b">');
    
      __out.push(gettext.gettext("No"));
    
      __out.push('</label>\n\n                </fieldset>\n            </div>\n        </div>\n    </div>\n\n    ');
    
      disp = '';
    
      __out.push('\n    ');
    
      if (this.hide_form) {
        __out.push('\n    ');
        disp = 'style="display: none;"';
        __out.push('\n    ');
      }
    
      __out.push('\n    <div id="user_account_block" ');
    
      __out.push(disp);
    
      __out.push('>\n        <div id="loginform_subsub">\n            <form id="user" action="" data-use="create">\n                <div class="form_fields grouped_fields">\n                    <div class="grouped_field">\n                        <label for="un">');
    
      __out.push(gettext.gettext("Username"));
    
      __out.push('</label>\n                        <input data-role="none" \n                               autocapitalize="off" \n                               autocorrect="off" \n                               type="text" \n                               name="username" \n                               id="un" \n                               value="" \n                               placeholder=".....................................">\n                    </div>\n                    <div class="grouped_field">\n                        <label for="pw">');
    
      __out.push(gettext.gettext("Password"));
    
      __out.push('</label>\n                        <input data-role="none" \n                               type="password" \n                               name="password" \n                               id="pw" \n                               value="" \n                               placeholder=".....................................">\n                    </div>\n                    <div class="grouped_field" id="email_field">\n                        <label for="em">');
    
      __out.push(gettext.gettext("E-mail"));
    
      __out.push('</label>\n                        <input data-role="none" \n                               autocapitalize="off" \n                               autocorrect="off" \n                               type="email" \n                               name="email" \n                               id="em" \n                               value="" \n                               placeholder=".....................................">\n                    </div>\n                </div>\n                <div class="validation_errors" />\n            </form>\n        </div>\n    </div>\n\n    <div class="sub_question_block">\n        <div data-role="fieldcontain" id="help_language">\n            <div class="ui-grid-a">\n                <div class="ui-block-a">\n                    <h2 class="legend no_disable">');
    
      __out.push(gettext.gettext("Translation language"));
    
      __out.push('</h2>\n                </div>\n                <div class="ui-block-b">&nbsp;</div>\n            </div>\n            <fieldset data-role="none" data-setting="help_language,interface_language,translation_language">\n                <div class="ui-grid-a">\n                    <div class="ui-block-a">\n                        <a type="button"\n                           data-theme="a"\n                           name="both-choice"\n                           id="both-choice-1"\n                           data-value="nob"\n                           data-mini="true">\n                        Norsk\n                        </a>\n                    </div>\n                    <div class="ui-block-b">\n                        <a type="button"\n                           data-theme="a"\n                           name="both-choice"\n                           id="both-choice-3"\n                           data-value="swe"\n                           data-mini="true">\n                        Svenska\n                        </a>\n                    </div>\n                </div>\n            </fieldset>\n        </div>\n    </div>\n\n    <div id="account_feedback">\n        <p style="display: none;" class="message" id="account_created">');
    
      __out.push(gettext.gettext("Your account was created, you may now begin!"));
    
      __out.push('</p>\n        <p style="display: none;" class="message" id="account_exists">');
    
      __out.push(gettext.gettext("You are logged in, and may now begin!"));
    
      __out.push('</p>\n    </div>\n\n    <div id="end">\n        <a href="#categoryMenu" class="begin_text" data-role="button" data-theme="b" id="start" data-mini="true" style="display: none;">\n            ');
    
      __out.push(gettext.gettext("Begin!"));
    
      __out.push('\n        </a>\n        <a href="#" data-role="button" class="login_text" data-theme="b" id="submit" data-mini="true">\n            ');
    
      __out.push(gettext.gettext("Log in"));
    
      __out.push('\n        </a>\n    </div>\n\n</div>\n\n');
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/intro/templates/loading", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div data-role="header">\n    <h1>Please wait...</h1>\n</div> \n\n<div data-role="content">\n    <p> Downloading some resources </p>\n    <pre></pre>\n</div> \n\n\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/intro/view", function(exports, require, module) {
var FrontPage, FrontPageTemplate, LoginErrorTemplate, _ref,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

FrontPageTemplate = require('./templates/front_page');

LoginErrorTemplate = require('/views/users/templates/login_error_modal');

module.exports = FrontPage = (function(_super) {
  __extends(FrontPage, _super);

  function FrontPage() {
    this.refreshTemplate = __bind(this.refreshTemplate, this);
    _ref = FrontPage.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  FrontPage.prototype.id = "frontPage";

  FrontPage.prototype.template = FrontPageTemplate;

  FrontPage.prototype.events = {
    "submit #user": "userForm",
    "click #submit": "userForm",
    "click #displayLogin": "displayLogin",
    "change #create-user-account-c": "displayLogin",
    "click #end a": "begin",
    "click #help_language [type='button']": "changeLanguage",
    "change #help_language [type='button']": "changeLanguage",
    "change #create_account [data-subquestion]": "revealUserForm",
    "change #create_account [data-hide-subquestion]": "hideUserForm",
    "change #create_account_or_login #login-or-new-a": "useCreateVariant",
    "change #create_account_or_login #login-or-new-b": "useLoginVariant"
  };

  FrontPage.prototype.begin = function(evt) {
    return DSt.set('gielese-configured', true);
  };

  FrontPage.prototype.useCreateVariant = function(evt) {
    this.$el.find('#email_field').slideDown();
    this.$el.find('#user').attr('data-use', 'create');
    DSt.set('form-create-or-not', 'create');
    if (evt != null) {
      if (!$(evt.target).attr('checked')) {
        return $(evt.target).attr('checked', true).checkboxradio('refresh');
      }
    }
  };

  FrontPage.prototype.useLoginVariant = function(evt) {
    this.$el.find('#email_field').slideUp();
    this.$el.find("#user #em").val('');
    this.$el.find('#user').attr('data-use', 'login');
    DSt.set('form-create-or-not', 'login');
    if (evt != null) {
      if (!$(evt.target).attr('checked')) {
        return $(evt.target).attr('checked', true).checkboxradio('refresh');
      }
    }
  };

  FrontPage.prototype.changeLanguage = function(evt) {
    var active, anon, fieldset, inactive, target_btn;
    anon = DSt.get('anonymous_selected');
    if (anon) {
      this.language_switched = true;
    }
    target_btn = $(evt.target).parents('[type="button"]');
    active = 'b';
    inactive = 'a';
    fieldset = $(evt.target).parents('fieldset');
    this.storeCurrentVisibleSetting(fieldset, target_btn);
    return true;
  };

  FrontPage.prototype.disableForm = function() {
    this.$el.find('#create_account fieldset').checkboxradio().checkboxradio('disable');
    this.$el.find('#create_account_or_login fieldset').checkboxradio().checkboxradio('disable');
    this.$el.find('h2.legend').addClass('disabled');
    return this.form_disabled = true;
  };

  FrontPage.prototype.enableForm = function() {
    this.$el.find('#create_account fieldset').checkboxradio().checkboxradio('enable');
    this.$el.find('#create_account_or_login fieldset').checkboxradio().checkboxradio('enable');
    this.$el.find('h2.legend').removeClass('disabled');
    return this.form_disabled = false;
  };

  FrontPage.prototype.revealUserForm = function(evt) {
    var sub;
    sub = $(evt.target).attr('data-subquestion');
    this.$el.find("#" + sub).slideDown();
    $('.login_text').show();
    $('.begin_text').hide();
    DSt.set('anonymous_selected', false);
    $('#create_account_or_login').fadeIn(200);
    $('#create_account_or_login_legend').fadeIn();
    return true;
  };

  FrontPage.prototype.hideUserForm = function(evt) {
    var sub;
    if (app.user) {
      app.auth.logout();
    }
    sub = $(evt.target).attr('data-hide-subquestion');
    this.$el.find("#" + sub).slideUp();
    $('.login_text').hide();
    $('.begin_text').show();
    DSt.set('anonymous_selected', true);
    $('#account_exists').hide();
    $('#account_created').hide();
    $('#create_account_or_login').fadeOut(200);
    $('#create_account_or_login_legend').fadeOut(200);
    return true;
  };

  FrontPage.prototype.displayLogin = function() {
    var _this = this;
    app.auth.render_authentication_popup(this.$el, {
      success: function() {
        return setTimeout(function() {
          app.auth.hide_authentication_popup(_this.$el);
          return window.location.hash = "#mainMenu";
        }, 250);
      }
    });
    return false;
  };

  FrontPage.prototype.hideLoading = function() {
    var interval;
    interval = setInterval(function() {
      $.mobile.loading('hide');
      return clearInterval(interval);
    }, 1);
    return false;
  };

  FrontPage.prototype.showLoading = function(txt) {
    var interval,
      _this = this;
    interval = setInterval(function() {
      $.mobile.loading('show', {
        text: txt,
        textVisible: true,
        theme: 'a',
        html: ""
      });
      return clearInterval(interval);
    }, 1);
    return false;
  };

  FrontPage.prototype.storeForm = function() {
    var form_data;
    form_data = {
      username: this.$el.find("#user #un").val(),
      email: this.$el.find("#user #em").val(),
      password: this.$el.find("#user #pw").val()
    };
    return DSt.set('login-details', form_data);
  };

  FrontPage.prototype.recallForm = function() {
    var create_or, ds;
    ds = DSt.get('login-details');
    if (ds) {
      this.$el.find("#user #un").val(ds.username);
      this.$el.find("#user #pw").val(ds.password);
      this.useLoginVariant();
    }
    create_or = DSt.get('form-create-or-not');
    if (create_or === "create") {
      this.$el.find('#email_field').show();
    }
    if (create_or === "login") {
      this.$el.find('#email_field').hide();
      this.$el.find("#user #em").val('');
      this.$el.find("#create_account_or_login #login-or-new-a").attr('checked', false).checkboxradio().checkboxradio('refresh');
      this.$el.find("#create_account_or_login #login-or-new-b").attr('checked', true).checkboxradio().checkboxradio('refresh');
    }
    return true;
  };

  FrontPage.prototype.userForm = function(event) {
    var form_sub_action, login_request, login_result, password, username,
      _this = this;
    this.showLoading("Submitting...");
    username = $("#user #un").val();
    password = $("#user #pw").val();
    form_sub_action = $('#user').attr('data-use');
    if (form_sub_action === 'create') {
      login_request = {
        username: $("#user #un").val(),
        email: $("#user #em").val(),
        password: $("#user #pw").val()
      };
    }
    if (form_sub_action === 'login') {
      login_request = {
        username: $("#user #un").val(),
        password: $("#user #pw").val()
      };
    }
    login_request.fail = function(resp) {
      var error, error_field, error_json, error_msg, fieldname, fields, fieldset, input, key, _results;
      error_json = JSON.parse(resp.responseText);
      fields = error_json.reasons;
      $("form#user input").removeClass("error");
      $("form#user span.error").remove();
      $("form .grouped_field.error").removeClass("error");
      if (fields) {
        for (fieldname in fields) {
          error = fields[fieldname];
          console.log([fieldname, error]);
          if (form_sub_action === 'login') {
            if (fieldname === 'username' || __indexOf.call(error, 'exists') >= 0) {
              _this.show_login_error(_this._LOGIN_ACCOUNT_ERROR_EXISTS, true, username);
              continue;
            }
          }
          error_field = $("input[name=" + fieldname + "]").parents('.grouped_field');
          error_msg = $("<div class='grouped_field_error'><span class='error'>" + error + "</span></div>");
          error_field.after(error_msg);
        }
        _results = [];
        for (key in fields) {
          error = fields[key];
          input = $("input[name=" + key + "]");
          input.addClass("error");
          fieldset = input.parents('.grouped_field');
          fieldset.addClass('error');
          error_msg = $("<span class='error'>");
          _results.push(error_msg.html(error.join(', ')));
        }
        return _results;
      } else {
        return _this.show_login_error(_this._LOGIN_ACCOUNT_ERROR_EXISTS, true, username);
      }
    };
    if (form_sub_action === 'create') {
      login_request.success = function(resp) {
        return app.auth.login({
          username: username,
          password: password,
          success: function() {
            setTimeout(_this.hideLoading, 500);
            $('.login_text').hide();
            $('.begin_text').show();
            $('#loginform_subsub').slideUp();
            $('#account_created').show();
            return DSt.store_form(app.frontPage.form[0]);
          }
        });
      };
    }
    this.$el.find('#fakeSubmit').click(function(evt) {
      $("#loginform_subsub").slideUp();
      return $("#loginform_success").show();
    });
    if (form_sub_action === 'create') {
      login_request.always = function(resp) {
        return setTimeout(_this.hideLoading, 500);
      };
    }
    if (form_sub_action === 'login') {
      login_request.success = function(resp) {
        setTimeout(_this.hideLoading, 500);
        if (app.user) {
          app.frontPage.storeForm();
          $("#loginform_success").show();
          $('#account_created').hide();
          $('#account_exists').show();
          $('#loginform_subsub').slideUp();
          $('.login_text').hide();
          $('.begin_text').show();
          return _this.disableForm();
        }
      };
    }
    if (form_sub_action === 'login') {
      login_result = app.auth.login(login_request);
    }
    if (form_sub_action === 'create') {
      login_result = app.auth.create_user(login_request);
    }
    return false;
  };

  FrontPage.prototype.storeCurrentVisibleSetting = function(fieldset, btn) {
    var checked_setting, key, refresh_template, setting_target, setting_value, _i, _len, _ref1;
    checked_setting = fieldset.find('input[type="radio"]:checked');
    setting_target = fieldset.attr('data-setting');
    setting_value = btn.attr('data-value');
    refresh_template = false;
    if (setting_target && setting_value) {
      _ref1 = setting_target.split(',');
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        key = _ref1[_i];
        if (key === "interface_language") {
          refresh_template = true;
        }
        app.options.setSetting(key, setting_value);
      }
    }
    if (refresh_template) {
      setTimeout(this.refreshTemplate, 500);
    }
    return true;
  };

  FrontPage.prototype.refreshTemplate = function() {
    var hide_form;
    DSt.store_form($('form#user')[0]);
    if (this.language_switched != null) {
      hide_form = true;
    } else {
      hide_form = false;
    }
    this.$el.html(this.template({
      hide_form: hide_form
    }));
    delete this.language_switched;
    $('[data-role=page]').trigger('pagecreate');
    this.loadSettings();
    return DSt.recall_form($('form#user')[0]);
  };

  FrontPage.prototype.loadSettings = function() {
    var active, anon, create_or, h_value, help_lang, inactive, resetCheck;
    help_lang = app.options.getSetting('help_language');
    h_value = "[data-value=" + help_lang + "]";
    active = 'b';
    inactive = 'a';
    resetCheck = function(vs, val) {
      return vs.attr('data-theme', val);
    };
    create_or = DSt.get('form-create-or-not');
    if (create_or === "create") {
      this.$el.find('#email_field').show();
    }
    if (create_or === "login") {
      this.$el.find('#email_field').hide();
      this.$el.find("#user #em").val('');
      this.$el.find("#create_account_or_login #login-or-new-a").attr('checked', false).checkboxradio().checkboxradio('refresh');
      this.$el.find("#create_account_or_login #login-or-new-b").attr('checked', true).checkboxradio().checkboxradio('refresh');
    }
    anon = DSt.get('anonymous_selected');
    if (this.form_disabled) {
      this.disableForm();
    }
    if (anon) {
      $('#create_account_or_login').hide();
      $('#create_account_or_login_legend').hide();
      $('#user_account_block').hide();
      $('#create-user-account-b').attr('checked', true).checkboxradio('refresh');
      $('#create-user-account-a').attr('checked', false).checkboxradio('refresh');
      $('.login_text').hide();
      $('.begin_text').show();
    }
    if (app.user) {
      $('#create_account_or_login').show();
      $('#user_account_block').hide();
      $('#create-user-account-b').attr('checked', false).checkboxradio('refresh');
      $('#create-user-account-a').attr('checked', true).checkboxradio('refresh');
      $('.login_text').hide();
      $('.begin_text').show();
      return $('#account_exists').show();
    }
  };

  FrontPage.prototype.show_login_error = function(msg, forgotten, username, try_again) {
    var login_template,
      _this = this;
    if (forgotten == null) {
      forgotten = false;
    }
    if (username == null) {
      username = false;
    }
    if (try_again == null) {
      try_again = true;
    }
    if (this.login_error_popup != null) {
      this.login_error_popup.remove();
    }
    login_template = LoginErrorTemplate({
      error_msg: msg,
      forgotten: forgotten,
      try_again: try_again
    });
    this.$el.append(login_template);
    this.login_error_popup = this.$el.find('#loginErrorPopup');
    this.login_error_popup.trigger('create');
    this.login_error_popup.popup().show().popup('open');
    if (forgotten) {
      this.login_error_popup.find('a#forget_button').click(function(e) {
        _this.login_error_popup.popup().popup('close');
        return app.auth.forgot({
          username: username,
          success: function() {
            app.frontPage.cur_msg = _this._LOGIN_ACCOUNT_CHECK_EMAIL;
            return setTimeout(function() {
              return app.frontPage.show_login_error(app.frontPage.cur_msg, false, false, false);
            }, 500);
          },
          fail: function() {
            app.frontPage.cur_msg = _this._LOGIN_ACCOUNT_NETWORK_ERROR;
            return setTimeout(function() {
              return app.frontPage.show_login_error(app.frontPage.cur_msg, true, username);
            }, 500);
          }
        });
      });
    }
  };

  FrontPage.prototype.render = function() {
    var hide_form, _EMAIL, _FORGET, _NETWORK;
    if (history.length > 1) {
      if (app.user) {
        app.auth.logout();
      } else {
        app.auth.clearUserData();
      }
    }
    this.total_questions = 2;
    this.questions_answered = 0;
    this.process_complete = false;
    this.enableForm();
    if (!DSt.get('form-create-or-not')) {
      DSt.set('form-create-or-not', 'create');
    }
    if (this.language_switched != null) {
      console.log("rendering with switched lang");
      hide_form = true;
    } else {
      hide_form = false;
    }
    this.$el.html(this.template({
      hide_form: hide_form
    }));
    this.form = this.$el.find('form');
    delete this.language_switched;
    _FORGET = gettext.gettext("Did you forget your password?");
    _EMAIL = gettext.gettext("Check your email!");
    _NETWORK = gettext.gettext("Check your network connection and try again");
    this._LOGIN_ACCOUNT_ERROR_EXISTS = _FORGET;
    this._LOGIN_ACCOUNT_CHECK_EMAIL = _EMAIL;
    this._LOGIN_ACCOUNT_NETWORK_ERROR = _NETWORK;
    this.loadSettings();
    this.recallForm();
    return this;
  };

  return FrontPage;

})(Backbone.View);
});

;require.register("views/splash/splash", function(exports, require, module) {
var SplashPage, SplashTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

SplashTemplate = require('./templates/splash');

module.exports = SplashPage = (function(_super) {
  __extends(SplashPage, _super);

  function SplashPage() {
    _ref = SplashPage.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  SplashPage.prototype.hideLoading = function() {
    var interval;
    interval = setInterval(function() {
      $.mobile.loading('hide');
      return clearInterval(interval);
    }, 1);
    return false;
  };

  SplashPage.prototype.showLoading = function(txt) {
    var interval,
      _this = this;
    interval = setInterval(function() {
      $.mobile.loading('show', {
        text: txt,
        textVisible: true,
        theme: 'a',
        html: ""
      });
      return clearInterval(interval);
    }, 1);
    return false;
  };

  SplashPage.prototype.id = "loading_splash";

  SplashPage.prototype.template = SplashTemplate;

  SplashPage.prototype.render = function() {
    this.$el.html(this.template);
    return this;
  };

  return SplashPage;

})(Backbone.View);
});

;require.register("views/splash/templates/splash", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div data-role="content">\n    <div id="splash_content">\n\n        <div id="big_logo">\n        </div>\n\n        <div id="splash_footer">\n            <div id="footer_version">\n                <span class="version">v. 0.1.0</span>\n            </div>\n            <div id="footer_logo">\n                <div id="logo">\n                    <img src="/static/images/aajege.png" />\n                    <span class="aajege">Aajege</span>\n                </div>\n                <div id="copy">\n                    <span class="copyright">&copy; 2013</span>\n                </div>\n            </div>\n        </div>\n    </div>\n</div> \n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/app_cache_status", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div id="loading_float">\n  <img src="/static/client/images/icon_loading_spinner.gif"/>\n  <span id="status">\n    <span id="message">Initializing offline cache ... </span>  \n    <span id="cache_count">&nbsp;</span>/<span id="cache_total">');
    
      __out.push(this.obj_count);
    
      __out.push('</span>\n  </span>\n</div>\n\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/leksa_concept", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var classes, linebreaks, val;
    
      if (this.concept_type === 'img') {
        __out.push('\n\n    ');
        classes = 'concept img_concept ';
        __out.push('\n    ');
        if (this.additional_class) {
          __out.push('\n        ');
          classes += this.additional_class;
          __out.push('\n    ');
        }
        __out.push('\n\n    <div class=\'');
        __out.push(classes);
        __out.push('\'>\n        <span class="concept_img_span" style=\'background-image: url(');
        __out.push(this.concept_value);
        __out.push(')\' />\n    </div>\n\n');
      } else if (this.concept_type === 'text') {
        __out.push('\n\n    ');
        linebreaks = /[-–—]/;
        __out.push('\n    ');
        val = this.concept_value.split(linebreaks).join('-<br />');
        __out.push('\n    <span class=\'concept word_concept\'>');
        __out.push(val);
        __out.push('</span>\n\n');
      }
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/sound_loading", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div id="sound_loading_bar" style="display: none;">\n    <img src="/static/images/ajax-loader.gif" width="16" height="16" /> \n    <p>Downloading audio...</p>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/login_modal", function(exports, require, module) {
var FrontPage, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = FrontPage = (function(_super) {
  __extends(FrontPage, _super);

  function FrontPage() {
    _ref = FrontPage.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  FrontPage.prototype.template = require('./templates/login_modal');

  FrontPage.prototype.render = function() {
    return this;
  };

  return FrontPage;

})(Backbone.View);
});

;require.register("views/users/options", function(exports, require, module) {
var GlobalOptionsView, OptionsTemplate, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

OptionsTemplate = require('./templates/options');

module.exports = GlobalOptionsView = (function(_super) {
  __extends(GlobalOptionsView, _super);

  function GlobalOptionsView() {
    _ref = GlobalOptionsView.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  GlobalOptionsView.prototype.id = 'global_options';

  GlobalOptionsView.prototype.events = {
    'click #save-options': 'saveOptions',
    'change #help_language': 'revealSubquestion',
    'change #help_language input': 'selectHelpLang',
    'change #help_language_2 input': 'saveOptions',
    'change #offline_fieldset select': 'saveOptions',
    'change #audio_fieldset select': 'saveOptions'
  };

  GlobalOptionsView.prototype.selectHelpLang = function(evt) {
    var $fieldset, target_fieldset, target_value;
    $fieldset = $(evt.target).parents('fieldset');
    target_fieldset = $fieldset.attr('data-copy-to');
    target_value = $fieldset.find('input[type="radio"]:checked').val();
    $("[data-setting='" + target_fieldset + "']").find("[type='radio']").attr("checked", false).checkboxradio("refresh");
    $("[data-setting='" + target_fieldset + "']").find("[value='" + target_value + "']").attr("checked", true).checkboxradio("refresh");
    this.saveOptions();
    return true;
  };

  GlobalOptionsView.prototype.revealSubquestion = function(evt) {
    var first, sub, sub_q, subs;
    sub_q = 'data-reveal-subquestion';
    subs = $("[" + sub_q + "]").attr(sub_q);
    $("#" + subs).slideUp();
    sub = $(evt.target).attr(sub_q);
    if (sub != null) {
      sub = $("#" + sub);
      sub.slideDown();
      first = sub.find(".ui-radio:first");
      first.find('input').attr('checked', true).checkboxradio("refresh");
    }
    return true;
  };

  GlobalOptionsView.prototype.saveOptions = function(evt) {
    var enable_audio, enable_cache, help_language, interface_language, new_settings, toBool, _audio, _data;
    if (app.debug === true) {
      console.log(evt);
    }
    toBool = function(v) {
      switch (v) {
        case "true":
          return true;
        case "false":
          return false;
      }
    };
    _data = this.$el.find('select[name="data-storage"]');
    _audio = this.$el.find('select[name="play-audio"]');
    enable_cache = toBool(_data.slider().val());
    enable_audio = toBool(_audio.slider().val());
    interface_language = $("[data-setting='interface_language']").find('input[type="radio"]:checked').val();
    help_language = $("[data-setting='help_language']").find('input[type="radio"]:checked').val();
    new_settings = {
      enable_cache: enable_cache,
      enable_audio: enable_audio,
      interface_language: interface_language,
      help_language: help_language
    };
    return app.options.setSettings(new_settings, {
      store: true
    });
  };

  GlobalOptionsView.prototype.template = OptionsTemplate;

  GlobalOptionsView.prototype.reloadSettings = function() {
    var hl, uil, _audio, _cache, _hl, _ui;
    _cache = this.$el.find('select[name="data-storage"]');
    _audio = this.$el.find('select[name="play-audio"]');
    uil = app.options.getSetting('interface_language');
    hl = app.options.getSetting('help_language');
    _ui = this.$el.find("[data-setting='interface_language'] input[value='" + uil + "']");
    _hl = this.$el.find("[data-setting='help_language'] input[value='" + hl + "']");
    _cache.val(app.options.getSetting('enable_cache').toString());
    _audio.val(app.options.getSetting('enable_audio').toString());
    _ui.attr("checked", true);
    return _hl.attr("checked", true);
  };

  GlobalOptionsView.prototype.render = function() {
    var hide_sub;
    if (app.options.getSetting('interface_language') === 'sma') {
      hide_sub = false;
    } else {
      hide_sub = true;
    }
    this.$el.html(this.template({
      hide_sub: hide_sub
    }));
    this.reloadSettings();
    return console.log("render");
  };

  return GlobalOptionsView;

})(Backbone.View);
});

;require.register("views/users/stats", function(exports, require, module) {
var CategoryLegend, HighScoreList, UserStats, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CategoryLegend = require('./templates/category_legend');

HighScoreList = require('./templates/high_scores');

module.exports = UserStats = (function(_super) {
  __extends(UserStats, _super);

  function UserStats() {
    _ref = UserStats.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  UserStats.prototype.id = "user_stats_page";

  UserStats.prototype.events = {
    'click .history_back': 'goBack',
    'change input': 'displayTab'
  };

  UserStats.prototype.displayTab = function(evt) {
    var new_tab,
      _this = this;
    new_tab = $(evt.target).attr('data-display-tab');
    return $('.stats-tab').fadeOut(300, function() {
      $("#" + new_tab).fadeIn(300);
      return $('.aajege-header h2').html($("#" + new_tab).attr('data-tab-title'));
    });
  };

  UserStats.prototype.goBack = function() {
    window.history.back();
    return false;
  };

  UserStats.prototype.template = require('./templates/stats');

  UserStats.prototype.initChart = function() {
    var arc, color, height, path, pie, radius, svg, width;
    width = 960;
    height = 500;
    radius = Math.min(width, height) / 2;
    color = d3.scale.category20();
    pie = d3.layout.pie().value(function(d) {
      return d.count;
    }).sort(null);
    arc = d3.svg.arc().innerRadius(radius - 100).outerRadius(radius - 20);
    svg = d3.select(_el).append("svg").attr("width", width).attr("height", height).append("g").attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
    path = svg.selectAll("path");
    return svg;
  };

  UserStats.prototype.categoryChart = function() {
    var arc, cat, catego, category_colors, col, color, color_range, height, pie, plotCategories, points, pretty_name, radius, svg, test_data, title, width, _el, _i, _len, _ref1, _ref2;
    catego = _.zip(app.categories.pluck('category'), app.categories.pluck('name'));
    color_range = ["#F7464A", "#437FEB", "#48CC92", "#DDD46D", "#E49247"];
    test_data = [
      {
        points: 30,
        color: "#F7464A",
        category: "omg",
        pretty_name: "Omg"
      }, {
        points: 50,
        color: "#E2EAE9",
        category: "bbq",
        pretty_name: "Bbq"
      }, {
        points: 100,
        color: "#D4CCC5",
        category: "lol",
        pretty_name: "löl"
      }, {
        points: 40,
        color: "#949FB1",
        category: "foo",
        pretty_name: "föö"
      }, {
        points: 120,
        color: "#4D5360",
        category: "bar",
        pretty_name: "bär"
      }
    ];
    category_colors = [];
    _ref1 = _.zip(catego, color_range);
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      _ref2 = _ref1[_i], cat = _ref2[0], col = _ref2[1];
      title = cat[0], pretty_name = cat[1];
      points = app.userprogression.points_for_category_name(title);
      if (points > 0) {
        category_colors.push({
          category: pretty_name,
          color: col,
          points: points
        });
      }
    }
    if (app.debug) {
      console.log(category_colors);
    }
    if (app.debug && app.userprogression.models.length === 0) {
      category_colors = test_data;
      console.log(category_colors);
    }
    width = $(document).width() - 20;
    height = 300;
    radius = Math.min(width, height) / 2;
    color = d3.scale.ordinal().range(color_range);
    arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(radius - 70);
    pie = d3.layout.pie().sort(null).value(function(d) {
      return d.points;
    });
    _el = this.$el.find("#category_use")[0];
    if ($(_el).find('svg')) {
      $(_el).find('svg').remove();
    }
    svg = d3.select(_el).append("svg").attr("width", width).attr("height", height).append("g").attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
    plotCategories = function(data) {
      var g;
      data.forEach(function(d) {
        return d.points = +d.points;
      });
      g = svg.selectAll(".arc").data(pie(data)).enter().append("g").attr("class", "arc");
      g.append("path").attr("d", arc).style("fill", function(d) {
        return color(d.data.category);
      });
      return g.append("text").attr("transform", function(d) {
        return "translate(" + arc.centroid(d) + ")";
      }).attr("dy", ".35em").style("text-anchor", "middle").text(function(d) {
        if (d.data.points > 0) {
          return d.data.category;
        }
      });
    };
    plotCategories(category_colors);
    return true;
  };

  UserStats.prototype.store_user_visibility = function(evt, ui) {
    var key, toBool, val;
    toBool = function(v) {
      switch (v) {
        case "true":
          return true;
        case "false":
          return false;
      }
    };
    key = 'highscore_visible';
    val = toBool($(evt.target).attr('data-highscore-visible'));
    if (app.user) {
      app.options.setSettings({
        highscore_visible: val
      }, {
        store: true
      });
    }
    return false;
  };

  UserStats.prototype.render = function() {
    var c, cat, categories, cats, correct_for_category, models, points, questions, questions_correct_for_category, questions_for_category, scores, total_questions_correct, total_questions_tried, user, _i, _j, _len, _len1,
      _this = this;
    models = app.userprogression.models;
    correct_for_category = {};
    if (app.userprogression.length > 0) {
      questions = app.userprogression.pluck('question').filter(function(q) {
        return q !== null;
      });
      cats = [];
      if (typeof cat !== "undefined" && cat !== null) {
        for (_i = 0, _len = cats.length; _i < _len; _i++) {
          cat = cats[_i];
          cats.push(cat);
        }
      }
      categories = _.uniq(cats);
      for (_j = 0, _len1 = categories.length; _j < _len1; _j++) {
        c = categories[_j];
        questions_for_category = app.userprogression.filter(function(l) {
          return l.get('question').category === c;
        });
        questions_correct_for_category = questions_for_category.filter(function(l) {
          return l.get('question_correct') === true;
        });
        total_questions_tried = questions_for_category.length;
        total_questions_correct = questions_correct_for_category.length;
        correct_for_category[c] = {
          'total': total_questions_tried,
          'correct': total_questions_correct,
          'percent': (total_questions_correct / total_questions_tried) * 100
        };
      }
    }
    if (app.userprogression.length > 0) {
      points = app.userprogression.countPoints();
    } else {
      points = false;
    }
    user = false;
    if (app.user) {
      user = true;
    }
    this.$el.html(this.template({
      logs: models,
      category_scores: correct_for_category,
      highscore_visible: app.options.getSetting('highscore_visible'),
      points_total: points,
      user: user
    }));
    if (app.userprogression.length > 0 || app.debug) {
      this.categoryChart();
    }
    this.$el.find('#display_stats input[type=radio]').on('change', this.store_user_visibility);
    scores = this.$el.find('div#high_scores');
    return $.get('/users/scores/', function(resp) {
      return scores.html(HighScoreList({
        highscores: resp.highscores
      }));
    });
  };

  return UserStats;

})(Backbone.View);
});

;require.register("views/users/templates/category_legend", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var category, _i, _len, _ref;
    
      __out.push('<ul>\n');
    
      _ref = this.items;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        category = _ref[_i];
        __out.push('\n    ');
        if (category.points > 0) {
          __out.push('\n        <li style="background-color: ');
          __out.push(category.color);
          __out.push('">');
          __out.push(category.name);
          __out.push('<br />');
          __out.push(category.points);
          __out.push('</li>\n    ');
        }
        __out.push('\n');
      }
    
      __out.push('\n</ul>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/templates/high_scores", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      var cur_class, entry, you_are_here_first, you_are_here_second, you_are_here_third, _i, _len, _ref;
    
      __out.push('<ul id="top_three">\n    ');
    
      you_are_here_second = "";
    
      __out.push('\n    ');
    
      if (app.user != null) {
        __out.push('\n        ');
        if (app.user.username === this.highscores[1].username) {
          __out.push('\n            ');
          you_are_here_second = "you_are_here";
          __out.push('\n        ');
        }
        __out.push('\n    ');
      }
    
      __out.push('\n    <li class="point_block second ');
    
      __out.push(you_are_here_second);
    
      __out.push('">\n        <ul class="score_set">\n            <li class="number">\n                <span class="circled-number"> 2 </span>\n            </li>\n            <li class="score_part username"><span class="txt">');
    
      __out.push(this.highscores[1].username);
    
      __out.push('</span class="txt"></li>\n            <li class="score_part points"><span class="txt">');
    
      __out.push(this.highscores[1].points);
    
      __out.push('</span class="txt"></li>\n        </ul>\n    </li>\n\n    ');
    
      you_are_here_first = "";
    
      __out.push('\n    ');
    
      if (app.user != null) {
        __out.push('\n        ');
        if (app.user.username === this.highscores[0].username) {
          __out.push('\n            ');
          you_are_here_first = "you_are_here";
          __out.push('\n        ');
        }
        __out.push('\n    ');
      }
    
      __out.push('\n    <li class="point_block first ');
    
      __out.push(you_are_here_first);
    
      __out.push('">\n        <ul class="score_set">\n            <li class="number">\n                <span class="circled-number"> 1 </span>\n            </li>\n            <li class="score_part username"><span class="txt">');
    
      __out.push(this.highscores[0].username);
    
      __out.push('</span class="txt"></li>\n            <li class="score_part points"><span class="txt">');
    
      __out.push(this.highscores[0].points);
    
      __out.push('</span class="txt"></li>\n        </ul>\n    </li>\n\n    ');
    
      you_are_here_third = "";
    
      __out.push('\n    ');
    
      if (app.user != null) {
        __out.push('\n        ');
        if (app.user.username === this.highscores[2].username) {
          __out.push('\n            ');
          you_are_here_third = "you_are_here";
          __out.push('\n        ');
        }
        __out.push('\n    ');
      }
    
      __out.push('\n    <li class="point_block third ');
    
      __out.push(you_are_here_third);
    
      __out.push('">\n        <ul class="score_set">\n            <li class="number">\n                <span class="circled-number"> 3 </span>\n            </li>\n            <li class="score_part username"><span class="txt">');
    
      __out.push(this.highscores[2].username);
    
      __out.push('</span class="txt"></li>\n            <li class="score_part points"><span class="txt">');
    
      __out.push(this.highscores[2].points);
    
      __out.push('</span class="txt"></li>\n        </ul>\n    </li>\n\n</ul>\n\n<ul id="point_list">\n    ');
    
      _ref = this.highscores.slice(3);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entry = _ref[_i];
        __out.push('\n        ');
        cur_class = "";
        __out.push('\n        ');
        if (app.user != null) {
          __out.push('\n            ');
          if (app.user.username === entry.username) {
            __out.push('\n                ');
            cur_class = "this_is_you";
            __out.push('\n            ');
          }
          __out.push('\n        ');
        }
        __out.push('\n        <li class="');
        __out.push(cur_class);
        __out.push('">\n            <span class="username">');
        __out.push(entry.username);
        __out.push('</span>\n            <span class="points">');
        __out.push(entry.points);
        __out.push('</span>\n        </li>\n    ');
      }
    
      __out.push('\n</ul>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/templates/login_error_modal", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div id="loginErrorPopup" \n     data-transition="pop" \n     data-theme="a">\n\n    <div id="loginPopupPadding">\n        <div id="fail">\n            ');
    
      __out.push(this.error_msg);
    
      __out.push('\n        </div>\n        ');
    
      if (this.try_again) {
        __out.push('\n            <a data-role="button" data-rel="back" type="submit" data-theme="b">');
        __out.push(gettext.gettext("Try again"));
        __out.push('</a>\n        ');
      } else {
        __out.push('\n            <a data-role="button" data-rel="back" type="submit" data-theme="b">');
        __out.push(gettext.gettext("Close"));
        __out.push('</a>\n        ');
      }
    
      __out.push('\n\n        ');
    
      __out.push(this.forgotten ? (__out.push('\n            <a data-role="button" data-rel="email" id="forget_button" type="" data-theme="a">'), __out.push(gettext.gettext("Email me")), __out.push('</a>\n        ')) : void 0);
    
      __out.push('\n    </div>\n\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/templates/login_modal", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div id="loginPopup" style="display: none;" data-transition="pop" data-theme="a">\n    ');
    
      if (this.logout) {
        __out.push('\n\n        <div id="loading" style="display: none;">\n            Sending... <span id="login_status">&nbsp;</span>\n        </div>\n        <div id="success" style="display: none;">\n            Success!\n        </div>\n        <div id="fail" style="display: none;">\n            You were not logged in. Are you connected, or was your password wrong?\n        </div>\n        \n    ');
      } else {
        __out.push('\n    <form id="login_form">\n        <div style="padding:10px 20px;">\n            <h3>Please sign in</h3>\n            <input autocapitalize="off" autocorrect="off" type="text" name="user" id="un" value="" placeholder="Username or e-mail" data-theme="a">\n            <input autocapitalize="off" autocorrect="off"type="password" name="pass" id="pw" value="" placeholder="password" data-theme="a">\n\n            <button type="submit" data-theme="b">Sign in</button>\n        </div>\n        <div id="loading" style="display: none;">\n            Sending... <span id="login_status">&nbsp;</span>\n        </div>\n        <div id="success" style="display: none;">\n            Success!\n        </div>\n        <div id="fail" style="display: none;">\n            You were not logged in. Are you connected, or was your password wrong?\n        </div>\n        <!-- TODO: close button? -->\n    </form>\n    ');
      }
    
      __out.push('\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/templates/options", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-left-arrow">\n            <a href="#mainMenu" data-transition="slide">\n                <span class="label">\n                    ');
    
      __out.push(gettext.gettext("Back"));
    
      __out.push('\n                </span>\n            </a>\n        </li>\n    </ul>\n    <h2>Options</h2>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content">\n    <form>\n        <ul data-role="listview" data-theme="j">\n            <li data-role="fieldcontain">\n                <fieldset id="help_language" data-role="controlgroup"  data-setting="interface_language" data-copy-to="help_language">\n                    <legend>');
    
      __out.push(gettext.gettext("Help language"));
    
      __out.push('</legend>\n                    <input class="nextSection" type="radio" name="radio-choice-1" id="radio-choice-1" value="nob" checked="checked">\n                    <label for="radio-choice-1">Norsk <img class="flag_ico" src="/static/images/flags/no_20x15.png" /></label>\n                    <input class="nextSection" type="radio" name="radio-choice-1" id="radio-choice-2" value="sma" data-reveal-subquestion="help_language_sub">\n                    <label for="radio-choice-2">Åarjelsaemien <img class="flag_ico" src="/static/images/flags/sma_20x15.png" /></label>\n                    <input class="nextSection" type="radio" name="radio-choice-1" id="radio-choice-3" value="swe">\n                    <label for="radio-choice-3">Svenska <img class="flag_ico" src="/static/images/flags/sv_20x15.png" /></label>\n                </fieldset>\n            </li>\n\n            <!-- TODO: this option will be in sync with the previous value unless\n                       the value is \'sma\'\n            -->\n\n            ');
    
      if (this.hide_sub) {
        __out.push('\n            <li data-role="fieldcontain" style="display: none;" id="help_language_sub">\n            ');
      } else {
        __out.push('\n            <li data-role="fieldcontain" id="help_language_sub">\n            ');
      }
    
      __out.push('\n                <fieldset id="help_language_2" data-role="controlgroup"  data-setting="help_language">\n                    <legend>');
    
      __out.push(gettext.gettext("Translation language"));
    
      __out.push('</legend>\n                    <input class="nextSection" type="radio" name="radio-choice-2" id="radio-choice-1" value="nob" checked="checked">\n                    <label for="radio-choice-1">Norsk <img class="flag_ico" src="/static/images/flags/no_20x15.png" /></label>\n                    <input class="nextSection" type="radio" name="radio-choice-2" id="radio-choice-2" value="swe">\n                    <label for="radio-choice-2">Svenska <img class="flag_ico" src="/static/images/flags/sv_20x15.png" /></label>\n                    <input class="nextSection" type="radio" name="radio-choice-2" id="radio-choice-3" value="eng">\n                    <label for="radio-choice-3">English <img class="flag_ico" src="/static/images/flags/en_20x15.png" /></label>\n                </fieldset>\n            </li>\n\n            <li data-role="fieldcontain">\n                <fieldset data-role="controlgroup" id="audio_fieldset">\n                    <legend>');
    
      __out.push(gettext.gettext("Play audio?"));
    
      __out.push('</legend>\n                    <select name="play-audio" \n                            id="play-audio" \n                            data-theme="d"\n                            data-track-theme="d"\n                            data-role="slider">\n                        <option value="false">');
    
      __out.push(gettext.gettext("No"));
    
      __out.push('</option>\n                        <option value="true">');
    
      __out.push(gettext.gettext("Yes"));
    
      __out.push('</option>\n                    </select>\n                </fieldset>\n            </li>\n\n            <li data-role="fieldcontain">\n                <fieldset data-role="controlgroup" id="offline_fieldset">\n                    <legend>Store data offline</legend>\n                    <select name="data-storage" \n                            id="data-storage" \n                            data-theme="d"\n                            data-track-theme="d"\n                            data-role="slider">\n                        <option value="false">');
    
      __out.push(gettext.gettext("No"));
    
      __out.push('</option>\n                        <option value="true">');
    
      __out.push(gettext.gettext("Yes"));
    
      __out.push('</option>\n                    </select>\n                </fieldset>\n            </li>\n\n            <li data-role="fieldcontain">\n                <fieldset data-role="controlgroup">\n                    <legend>Debug</legend>\n                    <div class="ui-grid-b">\n                        <div class="ui-block-a">\n                            <a class="square" href="#reset" data-transition="slide">\n                                <span class="link_word">Reset App</span>\n                            </a>\n                        </div>\n\n                        <div class="ui-block-b">\n                            <a class="square" href="#category/TEST" data-transition="slide">\n                                <span class="link_image"></span>\n                                <span class="link_word">Test Category</span>\n                            </a>\n                        </div>\n                    </div>\n                </fieldset>\n            </li>\n        </ul>\n    </form>\n\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/users/templates/stats", function(exports, require, module) {
var __templateData = function (__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="aajege-header aajege-header-shrinkable">\n    <ul class="aajege-nav aajege-nav-left">\n        <li class="icon-aajege-left-arrow">\n            <a href="#" class="history_back">\n            </a>\n        </li>\n    </ul>\n    <h2 class="kaushan">');
    
      __out.push(gettext.gettext("Top 10"));
    
      __out.push('</h2>\n    <hr class="aajege-flette" />\n</div>\n\n<div data-role="content">\n\n    <fieldset data-role="controlgroup" data-type="horizontal" id="subnav-control">\n    \t<input data-display-tab="high_scores_panel" \n    \t       type="radio" \n    \t       data-theme="a" \n    \t       name="radio-mini" \n    \t       id="radio-mini-1" \n    \t       value="choice-1" \n    \t       checked="checked" />\n    \t<label for="radio-mini-1">');
    
      __out.push(gettext.gettext("Top 10"));
    
      __out.push('</label>\n\n\t    <input data-display-tab="statistics" \n\t           type="radio" \n\t           data-theme="a" \n\t           name="radio-mini" \n\t           id="radio-mini-2" \n\t           value="choice-2" />\n    \t<label for="radio-mini-2">');
    
      __out.push(gettext.gettext("Statistics"));
    
      __out.push('</label>\n    </fieldset>\n    \n\n    <div id="high_scores_panel" class="stats-tab" data-tab-title="');
    
      __out.push(gettext.gettext("Top 10"));
    
      __out.push('">\n        <div id="high_scores">\n            ');
    
      __out.push(gettext.gettext("Loading..."));
    
      __out.push('\n        </div>\n        ');
    
      if (this.user) {
        __out.push('\n            <form id="display_stats">\n                <ul data-role="listview" data-inset="true">\n                    <li data-role="fieldcontain">\n                        <fieldset data-role="controlgroup" data-type="horizontal">\n                            <legend>');
        __out.push(gettext.gettext("Show my score to everyone?"));
        __out.push('</legend>\n                                <input type="radio" \n                                       name="radio-choice-b" \n                                       id="radio-choice-a"\n                                       data-highscore-visible="true"\n                                       ');
        if (this.highscore_visible) {
          __out.push('\n                                       checked="checked"\n                                       ');
        }
        __out.push('\n                                       >\n                                <label for="radio-choice-a">');
        __out.push(gettext.gettext("Yes"));
        __out.push('</label>\n                                <input type="radio"\n                                       name="radio-choice-b"\n                                       id="radio-choice-b"\n                                       ');
        if (!this.highscore_visible) {
          __out.push('\n                                       checked="checked"\n                                       ');
        }
        __out.push('\n                                       data-highscore-visible="false">\n                                <label for="radio-choice-b">');
        __out.push(gettext.gettext("No"));
        __out.push('</label>\n                        </fieldset>\n                    </li>\n                </ul>\n            </form>\n        ');
      } else {
        __out.push('\n            <p>');
        __out.push(gettext.gettext("You are playing anonymously, so your points may not be stored if you leave the app."));
        __out.push('</p>\n        ');
      }
    
      __out.push('\n    </div>\n\n\n    <div id="statistics" style="display: none;" class="stats-tab" data-tab-title="');
    
      __out.push(gettext.gettext("Your stats"));
    
      __out.push('">\n\n    ');
    
      if (this.points_total) {
        __out.push('\n        <h3>');
        __out.push(this.points_total);
        __out.push(' ');
        __out.push(gettext.gettext("points"));
        __out.push('</h3>\n    ');
      }
    
      __out.push('\n\n    ');
    
      if (this.logs.length > 0 || window.app.debug) {
        __out.push('\n\n        <div id="category_use" width="300" height="300">\n        </div>\n\n        <div id="category_chart">\n        <!-- -->\n            <tabl\n\n        </div>\n\n    ');
      } else {
        __out.push('\n\n        <h3>');
        __out.push(gettext.gettext("Learn some words to see stats!"));
        __out.push('</h3>\n\n    ');
      }
    
      __out.push('\n    </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;
//@ sourceMappingURL=app.js.map