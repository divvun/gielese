# -*- encoding: utf-8 -*-
from flask import ( Flask, request, redirect, session, json,
                    render_template, Response, url_for)

from werkzeug.routing import BaseConverter
from lexicon_models import db

def create_app():
    app = Flask(__name__, static_url_path='/static',)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/media_serv.db'
    db.init_app(app)
    return app, db


app, db = create_app()

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

    images = join_hosts(list_dir('static/images/'))

    from urllib import quote
    audios = join_hosts(map(quote, list_dir('static/audio/vce1/')))

    timestamp = datetime.strftime(datetime.today(), format='%Y-%M-%d %H:%M')

    networks = join_hosts([
        'static/client/javascripts/app.js',
        'static/client/javascripts/vendor.js',
        'static/client/stylesheets/app.css',
        # TODO: test
        '/data/concepts.json',
        '/data/leksa_questions.json',
    ])

    imgs = '\n'.join(images)
    audios = '\n'.join(audios)
    nets = '\n'.join(networks)

    # TODO: structure actually correct? missing CACHE? key
    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n\nCACHE:\n%(imgs)s\n%(audios)s\n%(nets)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\n\nFALLBACK:\n%(nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    return manifest_network + '\n'

@app.route('/offline.media.appcache', methods=['GET'])
def cache_manifest():
    from flask import Response

    return Response( create_manifest('http://%s/' % request.host)
                   , mimetype='text/cache-manifest')

@app.route('/data/leksa_questions.json', methods=['GET'])
def leksa_questions():
    from sample_json import leksa_questions
    from flask import json

    return json.dumps(leksa_questions).encode('utf-8')

@app.route('/data/concepts.json', methods=['GET'])
def concepts():
    from sample_json import sample_json
    from flask import json

    return json.dumps(sample_json).encode('utf-8')

@app.route('/', methods=['GET'])
def client():
    from flask import Response
    return render_template('index.html')

app.debug = True

if __name__ == "__main__":
    app.run(debug=True)
