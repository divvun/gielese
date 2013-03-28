
# -*- coding: utf-8 -*-

from flask.ext.sqlalchemy import SQLAlchemy
from sqlalchemy import UniqueConstraint

db = SQLAlchemy()

class Semtype(db.Model):
    __tablename__ = 'semtype'
    id = db.Column(db.Integer, primary_key=True)
    semtype = db.Column(db.String(50), unique=True)

    def __repr__(self):
        return "<Semtype '%s'>" % self.semtype

class Source(db.Model):
    __tablename__ = 'source'
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(20))
    name = db.Column(db.String(20))

    def __repr__(self):
        if self.type and self.name:
            return "<Source %s: %s>" % (self.type, self.name)
        elif self.name:
            return "<Source %s>" % self.name

class Dialect(db.Model):
    __tablename__ = 'dialect'
    id = db.Column(db.Integer, primary_key=True)
    dialect = db.Column(db.String(5))
    name = db.Column(db.String(100))

    def __repr__(self):
        if self.dialect and self.name:
            return "<Dialect %s: %s>" % (self.dialect, self.name)
        elif self.name:
            return "<Dialect %s>" % self.name
        elif self.dialect:
            return "<Dialect %s>" % self.dialect

class MorphPhonTag(db.Model):
    __tablename__ = 'morphphontag'
    id = db.Column(db.Integer, primary_key=True)
    stem         = db.Column(db.String(20))
    wordclass   = db.Column(db.String(20))
    diphthong   = db.Column(db.String(20))
    gradation   = db.Column(db.String(20))
    rime         = db.Column(db.String(20))
    soggi       = db.Column(db.String(20))

    __table_args__ = (UniqueConstraint( 'stem', 'wordclass', 'diphthong', 'gradation', 'rime', 'soggi',
                                         name='_morphophon_uc'),
                     )

    def __repr__(self):
        attrs = [ self.stem
                , self.wordclass
                , self.diphthong
                , self.gradation
                , self.rime
                , self.soggi
                ]

        S = unicode('/'.join([a for a in attrs if a.strip()])).encode('utf-8')
        return "<Morphophon: %s>" % S

# Many-To-Many intermediary table
word_semtype = db.Table( 'word_semtype'

                       , db.Column( 'word_id'
                                  , db.Integer
                                  , db.ForeignKey('word.id')
                                  )

                       , db.Column( 'semtype_id'
                                  , db.Integer
                                  , db.ForeignKey('semtype.id')
                                  )

                       )

# Many-To-Many intermediary table
word_source = db.Table( 'word_source'

                      , db.Column( 'word_id'
                                 , db.Integer
                                 , db.ForeignKey('word.id')
                                 )

                      , db.Column( 'source_id'
                                 , db.Integer
                                 , db.ForeignKey('source.id')
                                 )

                      )

# Many-To-Many intermediary table
word_dialect = db.Table( 'word_dialect'

                      , db.Column( 'word_id'
                                 , db.Integer
                                 , db.ForeignKey('word.id')
                                 )

                      , db.Column( 'dialect_id'
                                 , db.Integer
                                 , db.ForeignKey('dialect.id')
                                 )

                      )


class Word(db.Model):
    __tablename__ = 'word'
    id = db.Column(db.Integer, primary_key=True)
    wordid = db.Column(db.String(200), index=True)
    language = db.Column(db.String(5), index=True, default='sma')
    lemma = db.Column(db.String(200), index=True)
    presentationform = db.Column(db.String(5))
    pos = db.Column(db.String(12))
    stem = db.Column(db.String(20))
    wordclass = db.Column(db.String(8))
    valency = db.Column(db.String(10))
    hid = db.Column(db.Integer, nullable=True, default=None)
    semtype = db.relationship('Semtype', secondary=word_semtype,
                             backref=db.backref('words', lazy='dynamic'))
    source = db.relationship('Source', secondary=word_source,
                             backref=db.backref('words', lazy='dynamic'))
    diphthong = db.Column(db.String(5))
    gradation = db.Column(db.String(20))
    rime = db.Column(db.String(20))
    attrsuffix = db.Column(db.String(20))
    soggi = db.Column(db.String(10))
    compare = db.Column(db.String(5))
    frequency = db.Column(db.String(10))
    geography = db.Column(db.String(10))
    tcomm = db.Column(db.Boolean, default=False)
    morphophon = db.Column('morphphontag_id', db.Integer,
                           db.ForeignKey('morphphontag.id'), nullable=True)
    dialect = db.relationship('Dialect', secondary=word_dialect,
                             backref=db.backref('words', lazy='dynamic'))

    ### def morphTag(self, nosave=True):
    ###     try:
    ###         mphon = self.morphophon
    ###     except MorphPhonTag.DoesNotExist:
    ###         mphon = False
    ###     if not mphon:
    ###         kwargs = {
    ###             'stem':      self.stem,
    ###             'wordclass':    self.wordclass,
    ###             'diphthong':    self.diphthong,
    ###             'gradation':    self.gradation,
    ###             'rime':      self.rime,
    ###             'soggi':        self.soggi,
    ###         }
    ###         morphtag, create = MorphPhonTag.objects.get_or_create(**kwargs)
    ###         if nosave:
    ###             return morphtag
    ###         else:
    ###             self.morphophon = morphtag
    ###             self.save()

    ### def create(self, *args, **kwargs):
    ###     morphtag = self.morphTag()
    ###     self.morphophon = morphtag
    ###     self.pos = self.pos.lower().capitalize()
    ###     super(Word, self).create(*args, **kwargs)

    ### def save(self, *args, **kwargs):
    ###     """ Words model has an override to uppercase pos attribute on save,
    ###         in case data isn't saved properly.
    ###         """
    ###     morphtag = self.morphTag()
    ###     self.pos = self.pos.lower().capitalize()
    ###     self.morphophon = morphtag

    ###     super(Word, self).save(*args, **kwargs)

    def __repr__(self):
        return "<Word: %s>" % self.lemma

# Many-To-Many intermediary table
wordtranslation_semtype = db.Table( 'wordtranslation_semtype'

                        , db.Column( 'wordtranslation_id'
                                   , db.Integer
                                   , db.ForeignKey('wordtranslation.id')
                                   )

                        , db.Column( 'semtype_id'
                                   , db.Integer
                                   , db.ForeignKey('semtype.id')
                                   )

                        )

# Many-To-Many intermediary table
wordtranslation_source = db.Table( 'wordtranslation_source'

                       , db.Column( 'wordtranslation_id'
                                  , db.Integer
                                  , db.ForeignKey('wordtranslation.id')
                                  )

                       , db.Column( 'source_id'
                                  , db.Integer
                                  , db.ForeignKey('source.id')
                                  )

                       )

class WordTranslation(db.Model):
    """ Abstract parent class for all translations.
        Meta.abstract = True

        TODO: nullable=True necessary?
    """
    __tablename__ = 'wordtranslation'
    id = db.Column(db.Integer, primary_key=True)
    word = db.Column('word_id', db.Integer, db.ForeignKey('word.id'),
                     nullable=True, index=True)
    language = db.Column(db.String(5), index=True)
    wordid = db.Column(db.String(200), index=True)
    lemma = db.Column(db.String(200), nullable=True)
    phrase = db.Column(db.Text, nullable=True)
    explanation = db.Column(db.Text, nullable=True)
    pos = db.Column(db.String(12))
    semtype = db.relationship('Semtype', secondary=wordtranslation_semtype,
                             backref=db.backref('wordtranslations', lazy='dynamic'))
    source = db.relationship('Source', secondary=wordtranslation_source,
                             backref=db.backref('wordtranslations', lazy='dynamic'))
    frequency = db.Column(db.String(10))
    geography = db.Column(db.String(10))
    tcomm = db.Column(db.Boolean, default=False)
    tcomm_pref = db.Column(db.Boolean, default=False)

    def _getTrans(self):
        if self.lemma:
            return self.lemma
        elif self.phrase:
            return self.phrase
        elif self.explanation:
            return self.explanation
        else:
            return ''

    def _getAnswer(self):
        word_answers = []
        if self.lemma:
            word_answers.append(self.lemma)
        elif self.phrase:
            word_answers.append(self.phrase)
        return word_answers

    def __repr__(self):
        return self._getTrans().encode('utf-8')

    ### def save(self, *args, **kwargs):
    ###     self.definition = self._getTrans()
    ###     super(WordTranslation, self).save(*args, **kwargs)

    ### def __init__(self, *args, **kwargs):
    ###     super(WordTranslation, self).__init__(*args, **kwargs)
    ###     self.definition = self._getTrans()
    ###     self.word_answers = self._getAnswer()

class Tagset(db.Model):
    __tablename__ = 'tagset'
    id = db.Column(db.Integer, primary_key=True)
    tagset = db.Column(db.String(25))

    def __repr__(self):
        return self.tagset

class Tagname(db.Model):
    __tablename__ = 'tagname'
    id = db.Column(db.Integer, primary_key=True)
    tagname = db.Column(db.String(25))
    tagset = db.Column('tagset_id', db.Integer, db.ForeignKey('tagset.id'),
                     index=True)

    def __repr__(self):
        return self.tagname

class Tag(db.Model):
    __tablename__ = 'tag'
    id = db.Column(db.Integer, primary_key=True)
    string = db.Column(db.String(25))
    attributive = db.Column(db.String(5))
    case = db.Column(db.String(5))
    conneg = db.Column(db.String(5))
    grade = db.Column(db.String(10))
    infinite = db.Column(db.String(10))
    mood = db.Column(db.String(5))
    number = db.Column(db.String(5))
    personnumber = db.Column(db.String(8))
    polarity = db.Column(db.String(5))
    pos = db.Column(db.String(12))
    possessive = db.Column(db.String(5))
    subclass = db.Column(db.String(10))
    tense = db.Column(db.String(5))

    def __repr__(self):
        return self.string

# Many-To-Many intermediary table
form_dialect = db.Table( 'form_dialect'

                      , db.Column( 'form_id'
                                 , db.Integer
                                 , db.ForeignKey('form.id')
                                 )

                      , db.Column( 'dialect_id'
                                 , db.Integer
                                 , db.ForeignKey('dialect.id')
                                 )

                      )

class Form(db.Model):
    __tablename__ = 'form'
    id = db.Column(db.Integer, primary_key=True)
    word = db.Column('word_id', db.Integer, db.ForeignKey('word.id'),
                     index=True)
    tag = db.Column('tag_id', db.Integer, db.ForeignKey('word.id'),
                     index=True)
    fullform = db.Column(db.String(200))
    dialect = db.relationship('Dialect', secondary=form_dialect,
                             backref=db.backref('forms', lazy='dynamic'))

    def __repr__(self):
        return u'%s' % self.fullform.decode('utf-8')

