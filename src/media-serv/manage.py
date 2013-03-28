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

@manager.register('install_db')
def install_db(app):
    def action(media_filename=('m', 'mediafile')):
        from lexicon_models import Word
        from lexicon_install import install_media_references
        print media_filename
        install_media_references(db, media_filename)
    return action


if __name__ == "__main__":
    manager.run()
