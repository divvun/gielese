from . import blueprint
from flask import current_app

# TODO: validate with schematics

# TODO: auth - get user data to store in db from session, and totes do
#       not trust input

# TODO: return all user's data: stored options included
#       dirty?

#       _id vs id

# TODO: strip sid key?

# DOC: http://flask.pocoo.org/docs/views/ - class based view ideas

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

class SessionCheck(object):

    def session_user(self):
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

class LogsAPI(MethodView, SessionCheck):

    @property
    def table(self):
        return current_app.mongodb.db.user_logs

    def get(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        query = {"user_id": user_id}

        if item_id is not None:
            query["_id"] = ObjectId(item_id)
        return mongodoc_jsonify(data=self.table.find_one(query))

    def post(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: is this sufficient?
        request.json['user_id'] = user_id
        # TODO: can user create record?
        self.table.insert(request.json)
        return mongodoc_jsonify(data=request.json)

    create = post

    def delete(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user remove record?
        self.table.remove({"_id": ObjectId(item_id)})
        return ""

    def put(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user update record?

        # add user id
        request.json['user_id'] = user_id

        self.table.update({"_id": ObjectId(item_id)}, {'$set': request.json})
        return mongodoc_jsonify(data=request.json)

items_view = LogsAPI.as_view('items_api')

blueprint.add_url_rule( '/user/data/log/'
                      , defaults={'item_id': None}
                      , view_func=items_view
                      , methods=['GET',]
                      )

blueprint.add_url_rule( '/user/data/log/'
                      , view_func=items_view
                      , methods=['POST']
                      )

blueprint.add_url_rule( '/user/data/log/<item_id>'
                      , view_func=items_view
                      , methods=['GET', 'DELETE']
                      )

## User settings views

def pop_ids(obj):

    if isinstance(obj, dict):
        _obj = obj.copy()
        _obj.pop('_id')
        return _obj

    if isinstance(obj, list):
        return map(pop_ids, obj)

    return obj

class SettingsAPI(MethodView, SessionCheck):
    """ An object for storing settings for each user. Limit one object
    per user.
    """

    @property
    def table(self):
        return current_app.mongodb.db.user_settings

    def get(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        query = {"user_id": user_id}

        if item_id is not None:
            query["_id"] = ObjectId(item_id)
        return mongodoc_jsonify(data=pop_ids(self.table.find_one(query)))

    def delete_existing(self, user_id):
        qw = {'user_id': user_id}
        self.table.remove(qw)

    def post(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        self.delete_existing(user_id)

        # TODO: is this sufficient?
        print request.json
        request.json['user_id'] = user_id

        # TODO: can user create record?
        self.table.insert(request.json)
        return mongodoc_jsonify(data=request.json)

    create = post

    def delete(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        self.delete_existing(user_id)
        return ""

    def put(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user update record?
        self.delete_existing(user_id)

        # add user id
        request.json['user_id'] = user_id

        self.table.update({"_id": ObjectId(item_id)}, {'$set': request.json})
        return mongodoc_jsonify(data=request.json)

settings_view = SettingsAPI.as_view('settings_api')

blueprint.add_url_rule( '/user/settings/'
                      , defaults={'item_id': None}
                      , view_func=settings_view
                      , methods=['GET',]
                      )

blueprint.add_url_rule( '/user/settings/'
                      , view_func=settings_view
                      , methods=['POST', 'PUT']
                      )

