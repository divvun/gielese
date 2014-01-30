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

@manager.register('generate_key')
def generate_key(*args, **kwargs):
    import os
    def action():
        with open('secret_key', 'w') as F:
            F.write(os.urandom(24))
    return action

@manager.register('init_db')
# TODO: this seems to not work yet for some reason
def init_db(*args, **kwargs):
    def action():
        db.create_all(app=app)
        print "Models initialized"
    return action

def store_cache_file(data, filename):
    with open(filename, 'w') as F:
        F.write(data)
    return True

@manager.register('prepare_json')
def prepare_json(app):
    import json

    from media_serv import ( prepare_concepts
                           , prepare_leksa_questions
                           , prepare_translations
                           )

    def action():
        _file = "data/concepts.json"
        concepts = prepare_concepts(db)
        data = json.dumps(concepts)
        store_cache_file(data, _file)
        print " * Dumped %d concepts to %s" % (len(concepts), _file)

        _file = "data/leksa_questions.json"
        leksa_questions = prepare_leksa_questions()
        l_data = json.dumps(leksa_questions)
        store_cache_file(l_data, _file)
        print " * Dumped %d questions to %s" % (len(leksa_questions), _file)

        _file = "data/translations.json"
        translations = prepare_translations(db)
        t_data = json.dumps(translations)
        store_cache_file(t_data, _file)
        print " * Dumped %d questions to %s" % (len(translations), _file)

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
        print db.session.query(Concept).filter(Concept.lemma == u"rïhpestidh").first().translations_to.filter(Concept.language == 'mov').all()[0].media_format
        return
        print db.session.query(Concept).filter(Concept.lemma == u"rïhpestidh").first().toJSON()
        print db.session.query(Concept).filter(Concept.lemma == u"rïhpestidh").first().translations_to.all()
        print db.session.query(Concept).filter(Concept.lemma == u"rïhpestidh").first().translations_from.all()
        return
        print db.session.query(Concept).filter(Concept.lemma == "akte").first().toJSON()
        print db.session.query(Concept).filter(Concept.lemma == "akte").first().attributes
        return
        print db.session.query(Concept).filter(Concept.lemma == "aaloe").first().toJSON()

        print db.session.query(Concept).filter(Concept.lemma == "Garrah").first().translations_to.all()
        return

        # w = db.session.query(Word).filter_by(lemma=u'tjovrese').first()
        # print w.semtype
        # print w.translations.group_by('language').all()
        img = db.session.query(Concept).filter_by(lemma=u'/static/images/heelsedh/small/n_ii_ejte.jpg',
                                                   language='img').first()
        print img.semtype
        print img.translations_to.filter(Concept.language == 'sma').all()
        print img.translations_from.filter(Concept.language == 'sma').all()
        print img.translations_from.filter(Concept.language == 'sma').first().semtype
        return

        aalma = db.session.query(Concept).filter_by(lemma=u'ålma',
                                                   language='sma').first()

        print aalma.translations_to.all()
        aalma_img = aalma.translations_to.filter(Concept.language == 'mp3')
        f_aalma_img = aalma_img.first()
        print f_aalma_img
        print f_aalma_img.translations_to.filter(Concept.language == 'nob').all()

        aalma = db.session.query(Concept).filter_by(lemma=u'ålma',
                                                   language='sma').first()

        print aalma.translations_to.all()

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
