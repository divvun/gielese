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

    # TODO: structure actually correct? missing CACHE? key
    manifest_cache = dedent("""CACHE MANIFEST\n# %(timestamp)s\n\nCACHE:\n%(imgs)s\n%(audios)s\n%(nets)s""" % locals())
    manifest_network = manifest_cache + """\n\nNETWORK:\n%(nets)s\n\nFALLBACK:\n%(nets)s""" % locals()
    # TODO: add FALLBACK and options, etc.?

    manifest = manifest_network + '\n'
    return manifest.decode('utf-8')
