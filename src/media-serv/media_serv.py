# -*- encoding: utf-8 -*-
from flask import ( Flask, request, redirect, session, json,
                    render_template, Response)

from werkzeug.routing import BaseConverter

app = Flask(__name__, static_url_path='/static',)

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

    images = join_hosts(list_dir('static/images/')) + [
        "http://placekitten.com/250/150",
        "http://placedog.com/250/150",
        "http://dummyimage.com/250x150/000/900&text=granny",
        "http://dummyimage.com/250x150/000/900&text=fish",
        "http://dummyimage.com/250x150/000/900&text=fox",
    ]

    from urllib import quote
    audios = join_hosts(map(quote, list_dir('static/audio/')))

    timestamp = datetime.strftime(datetime.today(), format='%Y-%M-%d %H:%M')


    networks = [
        'static/client/javascripts/app.js',
        'static/client/javascripts/vendor.js',
        'static/client/stylesheets/app.css',
    ]

    imgs = '\n'.join(images)
    wavs = '\n'.join(audios)
    nets = '\n'.join(join_hosts(networks))

    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n%(imgs)s\n%(wavs)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\nFALLBACK:\n%(nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    return manifest_network + '\n'


@app.route('/offline.media.appcache', methods=['GET'])
def cache_manifest():
    from flask import Response

    return Response( create_manifest('http://localhost:5000/')
                   , mimetype='text/cache-manifest')


@app.route('/', methods=['GET'])
def client():
    from flask import Response
    return render_template('index.html')

if __name__ == "__main__":
    app.run(debug=True)

