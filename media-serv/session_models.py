""" Models for session and user data. See users. module for user
progression.
"""

from database import db
from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import validates

__all__ = [ 'Session'
          , 'User'
          ]

user_sessions = db.Table( 'user_sessions'

                        , db.Column( 'session_id'
                                   , db.Integer
                                   , db.ForeignKey('session.id')
                                   )

                        , db.Column( 'user_id'
                                   , db.Integer
                                   , db.ForeignKey('user.id')
                                   )

                        )

class Session(db.Model):
    __tablename__ = 'session'
    id = db.Column(db.Integer, primary_key=True)
    access_token = db.Column(db.String(64), unique=True)
    inet_addr = db.Column(db.Text)

    def __repr__(self):
        return "<Session %d / %s>" % (self.id, self.access_token)

class User(db.Model):
    __tablename__ = 'user'
    id = db.Column(db.Integer, primary_key=True)
    # Username will probably just be an email
    username = db.Column(db.Text)
    email = db.Column(db.Text)
    password = db.Column(db.String(64), unique=True)
    data = db.Column(db.Text)

    def __repr__(self):
        return "<User %d / %s: %s>" % (self.id)

    @validates('email')
    def validate_email(self, key, address):
        # TODO: more detailed validation
        assert '@' in address
        return address

