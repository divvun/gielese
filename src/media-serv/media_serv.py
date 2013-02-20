# -*- encoding: utf-8 -*-
from flask import ( Flask, request, redirect, session, json,
<<<<<<< HEAD
                    render_template, Response, url_for)
=======
                    render_template, Response)
>>>>>>> initial mediaserv: changing paths, moving files, app cache manifest,

from werkzeug.routing import BaseConverter

app = Flask(__name__, static_url_path='/static',)

<<<<<<< HEAD
@app.route('/favicon.ico')
def favicon():
    from flask import send_from_directory
    import os
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')



=======
>>>>>>> initial mediaserv: changing paths, moving files, app cache manifest,
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

<<<<<<< HEAD
    from urllib import quote
    audios = join_hosts(map(quote, list_dir('static/audio/')))
=======
    audios = join_hosts(list_dir('static/audio/'))
>>>>>>> initial mediaserv: changing paths, moving files, app cache manifest,

    timestamp = datetime.strftime(datetime.today(), format='%Y-%M-%d %H:%M')


    networks = join_hosts([
        'static/client/javascripts/app.js',
        'static/client/javascripts/vendor.js',
        'static/client/stylesheets/app.css',
        # TODO: test
        #'/data/concepts.json',
        #'/data/leksa_questions.json',
    ])

    imgs = '\n'.join(images)
    # wavs = '\n'.join(audios)
    wavs = '\n'.join([])
    nets = '\n'.join(networks)

    # TODO: structure actually correct? missing CACHE? key
    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n\nCACHE:\n%(imgs)s\n%(wavs)s\n%(nets)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\n\nFALLBACK:\n%(nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    return manifest_network + '\n'


@app.route('/offline.media.appcache', methods=['GET'])
def cache_manifest():
    from flask import Response

    return Response( create_manifest('http://%s/' % request.host)
                   , mimetype='text/cache-manifest')


# @app.route('/data/leksa_questions.json', methods=['GET'])
# def leksa_questions():
#     from sample_json import leksa_questions
#     from flask import json
# 
#     return json.dumps(leksa_questions).encode('utf-8')
# 
# @app.route('/data/concepts.json', methods=['GET'])
# def concepts():
#     from sample_json import sample_json
#     from flask import json
# 
#     return json.dumps(sample_json).encode('utf-8')

@app.route('/', methods=['GET'])
def client():
    from flask import Response
    return render_template('index.html')

app.debug = True

if __name__ == "__main__":
    app.run(debug=True)

