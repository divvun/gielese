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
    if not un:
        return plz_can_haz_auth()

    table = current_app.mongodb.db.user_logs

    user_names = dict(
        [(u.get('_id'), u.get('username')) for u in current_app.mongodb.db.users.find()]
    )
    pipeline = [
        {'$group':
            {'_id': '$user_id',
             'points': {'$sum': '$points'}}
        },
    ]
    points = table.aggregate(pipeline)

    users_and_points = []
    for r in points.get('result'):
        _r = r.copy()
        if _r['_id'] is not None:
            _r['username'] = user_names[_r['_id']]
            _r.pop('_id')
            users_and_points.append(_r)

    users_and_points = sorted( users_and_points
                             , key=itemgetter('points')
                             , reverse=True
                             )

    return mongodoc_jsonify(highscores=users_and_points)

