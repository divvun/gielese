# -*- encoding:utf-8 -*-

from flask import Flask
from flaskext.actions import Manager
from media_serv import create_app

app, db = create_app()
app.test_request_context().push()

manager = Manager(app)

@manager.register('init_db')
# TODO: this seems to not work yet for some reason
def init_db(*args, **kwargs):
    def action():
        db.create_all(app=app)
        print "Models initialized"
    return action

@manager.register('install_media')
def install_db(app):
    def action(media_filename=('f', 'mediafile')):
        from lexicon_install import install_media_references
        print media_filename
        install_media_references(db, media_filename)
    return action

# TODO: filter
@manager.register('append_lexical_data')
def append_lexical_data(app):
    def action(lexicon_filename=('f', 'lexiconfile')):
        from lexicon_install import append_lexicon
        print lexicon_filename
        append_lexicon(db, lexicon_filename)
    return action

@manager.register('install_lexicon')
def install_db_lex(app):
    def action(lexicon_filename=('f', 'lexiconfile')):
        from lexicon_install import install_lexical_data
        print lexicon_filename
        install_lexical_data(db, lexicon_filename)
    return action

@manager.register('test_some_queries')
def test_some_queries(app):
    def action():
        from lexicon_models import Word
        from lexicon_install import install_lexical_data

        w = db.session.query(Word).filter_by(lemma=u'tjovrese').first()
        print w.semtype
        print w.translations.group_by('language').all()

    return action

if __name__ == "__main__":
    manager.run()
