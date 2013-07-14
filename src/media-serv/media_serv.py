# -*- encoding: utf-8 -*-
from flask import ( Flask, request, redirect, session, json,
                    render_template, Response, url_for)

from werkzeug.routing import BaseConverter
from werkzeug.contrib.cache import SimpleCache
from database import db

def create_app():
    import os
    app = Flask(__name__, static_url_path='/static',)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////%s/media_serv.db' % os.getcwd()
    db.init_app(app)
    return app, db

cache = SimpleCache()
app, db = create_app()
app.config['cache'] = cache

@app.route('/favicon.ico')
def favicon():
    from flask import send_from_directory
    import os
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

app.jinja_env.line_statement_prefix = '#'

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

def create_manifest(app_host):
    from datetime import datetime
    from textwrap import dedent

    def list_dir(p):
        from os import listdir
        from os.path import isfile, join
        return [ join(p, f) for f in listdir(p)
                 if isfile(join(p, f)) ]

    def join_hosts(ps):
        return [app_host + p for p in ps]

    images = join_hosts(list_dir('static/images/')) + \
             join_hosts(list_dir('static/client/images/')) + \
             join_hosts(list_dir('static/images/ansikt/small/'))

    def quote_add_dir(s):
        return join_hosts(map(quote, list_dir(s)))

    from urllib import quote
             # quote_add_dir('static/audio/body/ED/') + \
             # quote_add_dir('static/audio/body/KB/') + \
    audios = \
             quote_add_dir('static/audio/body/AD/') + \
             quote_add_dir('static/audio/heelsedh/AD/') + \
             quote_add_dir('static/audio/heelsedh/ED/') + \
             quote_add_dir('static/audio/heelsedh/KB/') + \
             join_hosts(['static/client/swf/soundmanager2_debug.swf'])

    timestamp = datetime.strftime(datetime.today(), format='%Y-%M-%d %H:%M')

    networks = join_hosts([
        'static/client/javascripts/app.js',
        'static/client/javascripts/vendor.js',
        'static/client/stylesheets/app.css',
        # TODO: test
        'data/concepts.json',
        'data/leksa_questions.json',
    ])

    imgs = '\n'.join(images)
    audios = '\n'.join(audios)
    nets = '\n'.join(networks)

    # TODO: structure actually correct? missing CACHE? key
    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n\nCACHE:\n%(imgs)s\n%(audios)s\n%(nets)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\n\nFALLBACK:\n%(nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    manifest = manifest_network + '\n'
    return manifest.decode('utf-8')

def fmtForCallback(serialized_json, callback):
    if not callback:
        return serialized_json
    else:
        return "%s(%s)" % (callback, serialized_json)

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
    translations = ['sma', 'no', 'sv', 'en']
    data = [ {'locale': lx, 'messages': fetch_messages(lx)}
             for lx in translations ]
    return data

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


@app.route('/offline.media.appcache', methods=['GET'])
def cache_manifest():
    from flask import Response

    return Response( create_manifest('http://%s/' % request.host)
                   , mimetype='text/cache-manifest')

@app.route('/session/update/', methods=['POST'])
def generate_session():
    from session_models import Session

    # TODO: get user id, user access token from form

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    # get data from form, encode to string, and save session
    user_data = json.loads(request.form.get('user_data', False))

    # TODO: validate

    session.data = json.dumps(user_data)

    # TODO: TEST, right function, does it work?
    db.session.merge(session)

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False

@app.route('/session/token/', methods=['POST'])
def generate_session():
    from session_models import Session

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False

@app.route('/session/get/', methods=['POST'])
def generate_session():
    from session_models import Session

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False


@app.route('/session/generate/', methods=['GET'])
def generate_session():
    import uuid
    from session_models import Session

    _add = db.session.add

    user_id = uuid.uuid4()
    access_token = uuid.uuid4()

    sess = Session(user_id=user_id.hex, access_token=access_token.hex)
    _add(sess)

    return json.dumps({
        'user_id': user_id.hex,
        'access_token': access_token.hex,
    })

def prepare_leksa_questions(db):
    from sample_json import leksa_questions
    return leksa_questions

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
        leksa_questions = prepare_leksa_questions(db)

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

def format_concept(concept):
    # trick is that instead of Word and WordTranslation, need to have
    # Concept, so, need a new generic relationship? (Otherwise Words
    # will have id starting on 1, as will WordTranslations).
    from lexicon_models import Concept
    from sqlalchemy import and_

    langs = ["sma", "nob", "img"]

    def concept_filter(to_or_from):
        subset = to_or_from.filter(Concept.language.in_(langs))
        tcomm = subset.filter(Concept.tcomm_pref == True)
        if tcomm.count() > 0:
          subset = tcomm
        return set([ c.id for c in subset])

    _type = False
    features = []
    translations = list( concept_filter(concept.translations_to)
                       ^ concept_filter(concept.translations_from)
                       )

    concept_media = {}
    audio = concept.translations_to.filter(Concept.language == 'mp3').all()
    image = concept.translations_to.filter(Concept.language == 'img').all()

    media_ids = []

    if len(audio) > 0:
        concept_media['audio'] = [{'path': a.lemma} for a in audio]
        # media_ids.extend([a.id for a in audio])
    if len(image) > 0:
        concept_media['image'] = [{'path': a.lemma} for a in image]
        media_ids.extend([a.id for a in image])

    language = concept.language
    if language == 'img':
        _type = 'img'
    elif language == 'mp3':
        _type = 'mp3'
    else:
        _type = 'text'

    semantics = list((a.semtype for a in concept.semtype)) + \
                sum([[s.semtype for s in c.semtype] for c in concept.translations_from.all()], []) + \
                sum([[s.semtype for s in c.semtype] for c in concept.translations_to.all()], [])

    semantics = list(set(semantics))

    return { "id": concept.id
           , "concept_type": _type
           , "concept_value": concept._getTrans()
           , "features": features
           , "language": language
           , "updated_at": concept.updated_at.isoformat()
           , "created_at": concept.created_at.isoformat()
           , "semantics": semantics
           , "translations": list(set(translations)) + media_ids
           , "media": concept_media
           }

def prepare_concepts(db):
    from lexicon_models import Concept

    langs = ["sma", "nob", "img"]
    concept_set = db.session.query(Concept).filter(
        Concept.language.in_(langs)
    )
    concepts = map(format_concept, concept_set)

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

@app.route('/', methods=['GET'])
def landing():
    from flask import Response
    return render_template('landing.html')


@app.route('/play/', methods=['GET'])
def client():
    from flask import Response
    return render_template('index.html')

app.debug = True

if __name__ == "__main__":
    app.run(debug=True)
