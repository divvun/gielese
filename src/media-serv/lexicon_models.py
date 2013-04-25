﻿
# -*- coding: utf-8 -*-

from flask.ext.sqlalchemy import SQLAlchemy
from sqlalchemy import UniqueConstraint

db = SQLAlchemy()

# TODO: user progression data

class Session(db.Model):
    __tablename__ = 'session'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(64), unique=True)
    access_token = db.Column(db.String(64), unique=True)
    data = db.Column(db.Text)

    def __repr__(self):
        return "<Session %d / %s: %s>" % (self.id, self.user_id, self.access_token)

class Semtype(db.Model):
    __tablename__ = 'semtype'
    id = db.Column(db.Integer, primary_key=True)
    semtype = db.Column(db.String(50), unique=True)

    def __repr__(self):
        return "<Semtype '%s'>" % self.semtype.encode('utf-8')

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
concept_semtype = db.Table( 'concept_semtype'

                       , db.Column( 'concept_id'
                                  , db.Integer
                                  , db.ForeignKey('concept.id')
                                  )

                       , db.Column( 'semtype_id'
                                  , db.Integer
                                  , db.ForeignKey('semtype.id')
                                  )

                       )

# Many-To-Many intermediary table
concept_source = db.Table( 'concept_source'

                      , db.Column( 'concept_id'
                                 , db.Integer
                                 , db.ForeignKey('concept.id')
                                 )

                      , db.Column( 'source_id'
                                 , db.Integer
                                 , db.ForeignKey('source.id')
                                 )

                      )

# Many-To-Many intermediary table
concept_dialect = db.Table( 'concept_dialect'

                      , db.Column( 'concept_id'
                                 , db.Integer
                                 , db.ForeignKey('concept.id')
                                 )

                      , db.Column( 'dialect_id'
                                 , db.Integer
                                 , db.ForeignKey('dialect.id')
                                 )

                      )

concept_concept = db.Table( 'concept_to_concept'

                          , db.Column( 'left_concept_id'
                                     , db.Integer
                                     , db.ForeignKey('concept.id')
                                     , primary_key=True
                                     )

                          , db.Column( 'right_concept_id'
                                     , db.Integer
                                     , db.ForeignKey('concept.id')
                                     , primary_key=True
                                     )
                          )

class Concept(db.Model):
    __tablename__ = 'concept'
    id = db.Column(db.Integer, primary_key=True)
    wordid = db.Column(db.String(200), index=True)
    language = db.Column(db.String(5), index=True, default='sma')

    hid = db.Column(db.Integer, nullable=True, default=None)
    lemma = db.Column(db.String(200), index=True)
    phrase = db.Column(db.Text, nullable=True)
    explanation = db.Column(db.Text, nullable=True)
    stem = db.Column(db.String(20), nullable=True)

    pos = db.Column(db.String(12), nullable=True)
    wordclass = db.Column(db.String(8))
    valency = db.Column(db.String(10))

    semtype = db.relationship('Semtype', secondary=concept_semtype,
                             backref=db.backref('words', lazy='dynamic'))
    source = db.relationship('Source', secondary=concept_source,
                             backref=db.backref('words', lazy='dynamic'))
    frequency = db.Column(db.String(10))
    geography = db.Column(db.String(10))

    diphthong = db.Column(db.String(5))
    gradation = db.Column(db.String(20))
    rime = db.Column(db.String(20))
    attrsuffix = db.Column(db.String(20))
    soggi = db.Column(db.String(10))
    compare = db.Column(db.String(5))

    tcomm = db.Column(db.Boolean, default=False)
    tcomm_pref = db.Column(db.Boolean, default=False)

    translations_to = db.relationship("Concept",
                        secondary=concept_concept,
                        primaryjoin=id==concept_concept.c.left_concept_id,
                        secondaryjoin=id==concept_concept.c.right_concept_id,
                        backref=db.backref("translations_from", lazy='dynamic'),
                        lazy='dynamic'
    )

    morphophon = db.Column('morphphontag_id', db.Integer,
                           db.ForeignKey('morphphontag.id'), nullable=True)
    dialect = db.relationship('Dialect', secondary=concept_dialect,
                             backref=db.backref('words', lazy='dynamic'))

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
        return "<Concept: %s>" % self._getTrans().encode('utf-8')

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
    word = db.Column('word_id', db.Integer, db.ForeignKey('concept.id'),
                     index=True)
    tag = db.Column('tag_id', db.Integer, db.ForeignKey('tag.id'),
                     index=True)
    fullform = db.Column(db.String(200))
    dialect = db.relationship('Dialect', secondary=form_dialect,
                             backref=db.backref('forms', lazy='dynamic'))

    def __repr__(self):
        return u'%s' % self.fullform.decode('utf-8')
