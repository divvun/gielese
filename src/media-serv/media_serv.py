# -*- encoding: utf-8 -*-
import os, sys

from flask import ( Flask, request, redirect, session, json,
                    render_template, Response, url_for)

from werkzeug.routing import BaseConverter
from werkzeug.contrib.cache import SimpleCache
from database import db

from flask.ext.pymongo import PyMongo

class YamlConf(object):
    def __repr__(self):
        settings = dict([(k, self.__getattribute__(k)) for k in self.keys])
        return "<YamlConfig: %s>" % repr(settings)

    def __init__(self, *args, **kwargs):
        self.keys = set()

        for k, v in kwargs.iteritems():
            self.keys.add(k)
            if isinstance(v, dict):
                self.__setattr__(k, YamlConf(**v))
            else:
                self.__setattr__(k, v)

def apply_yaml_config(app, _yamlfile):
    import yaml

    with open(_yamlfile, 'r') as F:
        yaml_confs = yaml.load(F.read())

    for section, confs in yaml_confs.iteritems():
        if hasattr(app.config, section):
            print 'Renaming %s, key already exists in Flask config' % section
            sys.exit()
        setattr(app.config, section.lower(), YamlConf(**confs))

    return app


from flask_marrowmailer import Mailer

def create_app():
    _yamlfile = os.environ.get('MEDIA_SERV_CONF_PATH', 'gielese.app.config.yaml')

    app = Flask(__name__, static_url_path='/static',)

    app = apply_yaml_config(app, _yamlfile)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////%s/media_serv.db' % os.getcwd()
    db.init_app(app)
    mongo = PyMongo(app)
    app.mongodb = mongo
    # Mailer
    mailer = Mailer(app)
    app.mailer = mailer

    # Blueprints
    import auth
    import users
    app.register_blueprint(auth.blueprint)
    app.register_blueprint(users.blueprint)

    return app, db

cache = SimpleCache()
app, db = create_app()
app.config['cache'] = cache

@app.route('/favicon.ico')
def favicon():
    from flask import send_from_directory
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

# Using caveman for validation, but note, there is a django project for
# automatically producing manifests, when integration with smaoahpa
# happens

# http://pypi.python.org/pypi/caveman/1.0
# http://pypi.python.org/pypi/django_appcache/1.4
# http://pypi.python.org/pypi/django-manifest/0.1b4
# from caveman import ManifestChecker
# manifest_checker = ManifestChecker(logger=app.logger)
# get_url param for something that fetches each file and returns
# something.

def format_as_gettextjs(locale):
    import polib
    import json
    from operator import itemgetter

    def get_message_data(m):

        pl_msgid = m.msgid_plural.strip() and True or False
        pl_msgstrs = len(m.msgstr_plural.keys()) > 0
        if pl_msgid and pl_msgstrs:
            # Try to sort by ID number, if it doesn't work, well, that sucks
            numerii = list(m.msgstr_plural.iteritems())

            try:
                numerii = [(int(a), b) for a, b in numerii]
            except:
                pass

            numerii = map(itemgetter(1), sorted(numerii, key=itemgetter(0)))

            return (m.msgid, numerii)

        if m.msgstr is not None:
            return (m.msgid, [None, m.msgstr])

    def fmt_pofile(filename):
        try:
            po = polib.pofile(filename)
        except:
            return {}

        domain = po.metadata.get('domain', 'messages')
        out_meta = { 'domain': domain
                   , 'lang': po.metadata.get('Language', '')
                   , 'plural-forms': po.metadata.get('Plural-Forms', '')
                   }

        messages = dict(map(get_message_data, po.translated_entries()))

        out_json = { '': out_meta
                   }

        out_json.update(**messages)

        return {domain: out_json}

    _pofile = fmt_pofile('translations/%s/LC_MESSAGES/messages.po' % locale)

    return _pofile

def fetch_messages(locale):
    from polib import pofile

    try:
        _pofile = pofile('translations/%s/LC_MESSAGES/messages.po' % locale)
    except:
        return {}

    jsentries = filter( lambda x: any(['.js' in a[0] for a in x.occurrences])
                      , list(_pofile)
                      )

    return dict( [(e.msgid, e.msgstr or False) for e in jsentries] )

def prepare_translations(db):
    data = [ {'locale': lx, 'messages': fetch_messages(lx)}
             for lx in app.config.languages.localization_languages ]
    return data

##
### JSON data files endpoints
##

# TODO: move these to own module.

def fmtForCallback(serialized_json, callback):
    if not callback:
        return serialized_json
    else:
        return "%s(%s)" % (callback, serialized_json)


@app.route('/data/translations.json', methods=['GET'])
def bookmarklet_configs():
    """ Compile a JSON response containing dictionary pairs,
    and internationalization strings.
    """
    from flaskext.babel import get_locale

    has_callback = request.args.get('callback', False)

    with open('data/translations.json', 'r') as F:
        json_data = F.read().strip()

    formatted = fmtForCallback(json_data, has_callback)

    return Response( response=formatted
                   , status=200
                   , mimetype="application/json"
                   )

@app.route('/data/translations/<locale>/messages.json', methods=['GET'])
def get_messages_for(locale):
    has_callback = request.args.get('callback', False)

    pretty = request.args.get('pretty', False)
    json_data = format_as_gettextjs(locale)

    if pretty:
        data = json.dumps( json_data
                         , sort_keys=True
                         , indent=4
                         , separators=(',', ': ')
                         )
    else:
        data = json.dumps(json_data)

    formatted = fmtForCallback(data, has_callback)

    return Response( response=formatted
                   , status=200
                   , mimetype="application/json"
                   )

@app.route('/offline.media.appcache', methods=['GET'])
def cache_manifest():
    from flask import Response
    from app_manifest import create_manifest

    return Response( create_manifest('http://%s/' % request.host)
                   , mimetype='text/cache-manifest')

def prepare_leksa_questions():
    import yaml
    with open(app.config.games.leksa.file, 'r') as F:
        data = yaml.load(F.read())

    questions = data.get('DefaultQuestions') + data.get('Questions')

    return questions

@app.route('/data/leksa_questions.json', methods=['GET'])
def leksa_questions():
    from flask import json

    pretty = request.args.get('pretty', False)
    reprepare = request.args.get('force_prepare', False)

    if not reprepare:
        with open('data/leksa_questions.json', 'r') as F:
            json_data = F.read().strip()

        return Response( response=json_data
                       , status=200
                       , mimetype="application/json"
                       )
    else:
        leksa_questions = prepare_leksa_questions()

        if pretty:
            data = json.dumps( leksa_questions
                             , sort_keys=True
                             , indent=4
                             , separators=(',', ': ')
                             )
        else:
            data = json.dumps(leksa_questions)

        return Response( response=data.encode('utf-8')
                       , status=200
                       , mimetype="application/json"
                       )

def prepare_concepts(db):
    from lexicon_models import Concept

    langs = ["sma", "nob", "img", "swe"]
    concept_set = db.session.query(Concept).filter(
        Concept.language.in_(langs)
    )
    concepts = [c.toJSON(with_langs=langs) for c in concept_set]

    return concepts

@app.route('/data/concepts.json', methods=['GET'])
def concepts():
    from flask import json

    reprepare = request.args.get('force_prepare', False)
    if not reprepare:
        with open('data/concepts.json', 'r') as F:
            json_data = F.read().strip()

        return Response( response=json_data
                       , status=200
                       , mimetype="application/json"
                       )

    else:
        cached = cache.get('concepts.json')
        pretty = bool(request.args.get('pretty', False))

        if not cached:
            concepts = prepare_concepts(db)
            cache.set('concepts.json', concepts)
        else:
            concepts = cached

        if pretty:
            data = json.dumps( concepts
                             , sort_keys=True
                             , indent=4
                             , separators=(',', ': ')
                             )
        else:
            data = json.dumps(concepts)

        with open('data/concepts.json', 'w') as F:
            F.write(data)

        return Response( response=data.encode('utf-8')
                       , status=200
                       , mimetype="application/json"
                       )

def read_categories():
    """ Minify.
    """
    from flask import json

    with open('data/categories.json', 'r') as F:
        json_data = json.loads(F.read().strip())
        json = json.dumps(json_data)

    return json

# TODO: merge this with the above concept thing, it's basically the
# same.
@app.route('/data/categories.json', methods=['GET'])
def categories():
    from flask import json

    reprepare = request.args.get('force_prepare', False)

    if not reprepare:
        try:
            return Response( response=read_categories()
                           , status=200
                           , mimetype="application/json"
                           )
        except IOError:
            pass

    cached = cache.get('categories.json')
    pretty = bool(request.args.get('pretty', False))

    if not cached:
        categories = read_categories(db)
        cache.set('categories.json', categories)
    else:
        categories = cached

    categories = {
        'categories': categories
    }

    if pretty:
        data = json.dumps( categories
                         , sort_keys=True
                         , indent=4
                         , separators=(',', ': ')
                         )
    else:
        data = json.dumps(categories)

    with open('data/categories.json', 'w') as F:
        F.write(data)

    return Response( response=data.encode('utf-8')
                   , status=200
                   , mimetype="application/json"
                   )

##
### Front page and brunch serving view
##

@app.route('/', methods=['GET'])
def client():
    from flask import Response
    return render_template('index.html')

@app.route('/video-test/', methods=['GET'])
def video_test():
    from flask import Response
    return render_template('video_test.html')

@app.route('/play/offline/', methods=['GET'])
def client_offline():
    from flask import Response
    return render_template('offline_index.html')

app.debug = True

with open('secret_key', 'r') as F:
    app.secret_key = F.read().strip()

if __name__ == "__main__":
    app.run(debug=True)
