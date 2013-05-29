# -*- encoding:utf-8 -*-

from flask import Flask
from flaskext.actions import Manager
from media_serv import create_app

app, db = create_app()
app.test_request_context().push()

manager = Manager(app, default_server_actions=True)

def thing():
    from lexicon_models import Concept
    a = Concept(lemma='omg')
    b = Concept(lemma='bbq')
    a.translations_to.append(b)
    b.translations_from.append(a)


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
        from lexicon_models import Concept, Semtype
        from lexicon_install import install_lexical_data
        from media_serv import format_concept

        # w = db.session.query(Word).filter_by(lemma=u'tjovrese').first()
        # print w.semtype
        # print w.translations.group_by('language').all()

        aalma = db.session.query(Concept).filter_by(lemma=u'ålma',
                                                   language='sma').first()

        print aalma.translations_to.all()
        aalma_img = aalma.translations_to.filter(Concept.language == 'mp3')
        f_aalma_img = aalma_img.first()
        print f_aalma_img
        print f_aalma_img.translations_to.filter(Concept.language == 'nob').all()

        return

        gaalloe = db.session.query(Concept).filter_by(lemma='gaalloe',
                                                   language='sma').first()

        print gaalloe.translations_to.all()
        print gaalloe.translations_from.all()
        # print gaalloe.translations_from[0].semtype

        semtype = db.session.query(Semtype).filter_by(semtype='MORFAS').first()
        print semtype.words.all()

        skaavtjoe = db.session.query(Concept).filter_by(lemma='skaavtjoe',
                                                   language='sma').first()
        skaavtjoe_img = skaavtjoe.translations_to.filter(Concept.language == 'img')
        f_skaavtjoe_img = skaavtjoe_img.first()

        # print format_concept(skaavtjoe)
        print '--'
        print 'img test'
        print format_concept(skaavtjoe_img)
        print skaavtjoe_img.translations_to.all()
        print skaavtjoe_img.translations_from.all()

    return action

if __name__ == "__main__":
    manager.run()
