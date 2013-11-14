from . import blueprint
from flask import current_app

from bson import ObjectId
from datetime import datetime
from flask import Response, session, jsonify, request
from flask import request
from flask.views import MethodView
from functools import wraps
import simplejson

class MongoDocumentEncoder(simplejson.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime):
            return o.isoformat()
        elif isinstance(o, ObjectId):
            return str(o)
        return simplejson.JSONEncoder(self, o)


def mongodoc_jsonify(*args, **kwargs):
    return Response( simplejson.dumps( dict(*args, **kwargs)
                                     , cls=MongoDocumentEncoder
                                     )
                   , mimetype='application/json'
                   )

from auth.views import plz_can_haz_auth

def session_user():
    users = current_app.mongodb.db.users

    un = None
    user_id = None

    if 'username' in session:
        un = session['username']
        if un:
            user = users.find_one({"username": un})
            user_id = user.get('_id')

    print "session: %s, %s" % (str(un), str(user_id))

    return un, user_id

@blueprint.route("/users/scores/", methods=['GET'])
def get_highscores():
    from operator import itemgetter

    un, user_id = session_user()
    anonymize = False
    if not un:
        anonymize = True

    logs_table = current_app.mongodb.db.user_logs
    settings = current_app.mongodb.db.user_settings
    users_table = current_app.mongodb.db.users

    # All user visibility options
    _visibility_opts = settings.find({
        u'setting_key': u'highscore_visible',
    })

    user_visibilities = dict(
        [(u.get('user_id'), u.get('setting_value')) for u in _visibility_opts]
    )

    # Only users with visibility that exists, and is set to False,
    # meaning they don't want to be shown.
    hidden_user_ids = [_uid for _uid, _vis in user_visibilities.iteritems()
                       if _vis == False]

    points = logs_table.aggregate([
        # Users not in hidden
        {'$match':
            {'user_id': {'$nin': hidden_user_ids}}
        },
        # group and sum points
        {'$group':
            {'_id': '$user_id',
             'points': {'$sum': '$points'}}
        },
    ])

    user_names = dict(
        [(u.get('_id'), u.get('username')) for u in users_table.find()]
    )

    # now we add in usernames
    users_and_points = []
    for r in points.get('result'):
        _r = r.copy()
        if _r['_id'] is not None:
            _r['username'] = user_names[_r['_id']]
            _r.pop('_id')
            users_and_points.append(_r)

    # If user is anonymous, we'll obscure usernames just a bit...

    def anonymize_name(score):
        _un = score['username']
        score['username'] =  _un[0] + ((len(_un) - 1) * u'.')
        return score

    if anonymize:
        users_and_points = map(anonymize_name, users_and_points)

    # sort
    users_and_points = sorted( users_and_points
                             , key=itemgetter('points')
                             , reverse=True
                             )

    return mongodoc_jsonify(highscores=users_and_points)

