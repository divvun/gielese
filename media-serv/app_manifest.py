﻿""" An app manifest is a required part of offline HTML5 apps. It tells
the browser which files to store and use locally, and which files must
be used live on the server. This allows you to define cached media
directories alongside live API endpoints.

For additional information:

 * http://appcachefacts.info/
 * http://diveintohtml5.info/offline.html


"""


def create_manifest(app_host):
    from datetime import datetime
    from textwrap import dedent

    def list_dir(p):
        """ List the files in a directory """
        from os import listdir
        from os.path import isfile, join, isdir
        this_dir = [ join(p, f) for f in listdir(p) if isfile(join(p, f)) and not f.startswith('.')]
        subdirs = [ list_dir(join(p, d)) for d in listdir(p) if isdir(join(p, d)) ]
        return this_dir + sum(subdirs, [])

    def join_hosts(ps):
        """ Join the host with a path """
        return [app_host + p for p in ps]

    # These are our image files.
    # TODO: this is too specific now, need to generalize.
    images = join_hosts(list_dir('static/client/images/')) + \
             join_hosts(list_dir('static/nature_animals/img/small/')) + \
             join_hosts(list_dir('static/nature_world/img/small/')) + \
             join_hosts(list_dir('static/images/icons/')) + \
             join_hosts(list_dir('static/images/flags/')) + \
             join_hosts(list_dir('static/images/food/small/')) + \
             join_hosts(list_dir('static/images/phrases/small/')) + \
             join_hosts(list_dir('static/images/heelsedh/small/')) + \
             join_hosts(list_dir('static/images/ansikt/small/'))

    def quote_add_dir(s):
        """ Join the host, and encode the URL. """
        return join_hosts(map(quote, list_dir(s)))

    from urllib import quote

    audios = quote_add_dir('static/audio/') + \
             quote_add_dir('static/nature_animals/mp3/') + \
             quote_add_dir('static/nature_world/mp3/') + \
             join_hosts(['static/client/swf/soundmanager2_debug.swf'])

    timestamp = datetime.strftime(datetime.today(), format='%Y-%M-%d %H:%M')

    networks = join_hosts([
        'static/client/javascripts/app.js',
        'static/client/javascripts/vendor.js',
        'static/client/stylesheets/app.css',
        # TODO: test
        # TODO: get all json files
        'data/concepts.json',
        'data/leksa_questions.json',
        # TODO: test
        'data/translations/sv/messages.json',
        'data/translations/no/messages.json',
        'data/translations/sma/messages.json',
        'data/translations/en/messages.json',
    ])

    imgs = '\n'.join(images)
    audios = '\n'.join(audios)
    nets = '\n'.join(networks)
    fallback_nets = '\n'.join(networks + ['*'])

    # TODO: structure actually correct? missing CACHE? key
    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n\nCACHE:\n%(imgs)s\n%(audios)s\n%(nets)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\n\nFALLBACK:\n%(fallback_nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    manifest = manifest_network + '\n'
    return manifest.decode('utf-8')
