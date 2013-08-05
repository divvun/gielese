from . import blueprint
from flask import current_app

from bson import ObjectId
from datetime import datetime
from flask import Response, session, jsonify, request
from flask import request
from flask.views import MethodView
from functools import wraps
import simplejson

# TODO: validate with schematics

# TODO: auth - get user data to store in db from session, and totes do
#       not trust input

# TODO: return all user's data: stored options included
#       dirty?

#       _id vs id

# TODO: strip sid key?

# DOC: http://flask.pocoo.org/docs/views/ - class based view ideas
# DOC: http://api.mongodb.org/python/current/api/pymongo/collection.html


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
        logs = self.table.find(query)

        if logs is None:
            logs = []

        def switch_id(model):
            if '_id' in model:
                _id = model.get('_id')
                c_id = model.get('c_id')
                model.pop('_id')
                model.pop('c_id')
                model['id'] = c_id
            return model

        logs = map(switch_id, logs)
        return mongodoc_jsonify(data=logs)

    def post(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: is this sufficient?
        request.json['user_id'] = user_id
        # TODO: can user create record?
        def switch_id(model):
            if '_id' in model:
                _id = model.get('_id')
                model.pop('_id')
                model['c_id'] = _id
                # model['_id'] = ObjectId(_id)
            return model
        cleaned = switch_id(request.json)
        self.table.insert(cleaned)
        return mongodoc_jsonify(data=request.json)

    create = post
    put = post

    def delete(self, item_id):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user remove record?
        self.table.remove({"_id": ObjectId(item_id)})
        return ""

items_view = LogsAPI.as_view('items_api')

blueprint.add_url_rule( '/user/data/log/'
                      , defaults={'item_id': None}
                      , view_func=items_view
                      , methods=['GET',]
                      )

# TODO: put -- make sure that update and replace stuff is figured out 
blueprint.add_url_rule( '/user/data/log/'
                      , view_func=items_view
                      , methods=['POST', 'PUT']
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
    """ An object for storing settings for each user.  """

    @property
    def table(self):
        return current_app.mongodb.db.user_settings

    def get(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        query = {"user_id": user_id}

        def clean_setting(s):
            def tryPop(d, k):
                try: d.pop(k)
                except: pass
                return d

            _s = pop_ids(s)
            _s = tryPop(_s, 'user_id')
            _s = tryPop(_s, 'dirty')
            _s = tryPop(_s, 'sid')
            _s = tryPop(_s, 'updated_at')
            _s = tryPop(_s, 'created_at')

            return _s

        return mongodoc_jsonify(settings=map(clean_setting, self.table.find(query)))

        # return mongodoc_jsonify(data=[pop_ids(self.table.find(query))])

    def post(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user update record?
        request.json['user_id'] = user_id
        setting_key = request.json.get('setting_key')

        existing_query = {'user_id': user_id, 'setting_key': setting_key}

        self.table.remove(existing_query)
        self.table.insert({ 'user_id': user_id
                          , 'setting_key': setting_key
                          , 'setting_value': request.json.get('setting_value')
                          })

        return mongodoc_jsonify(data=request.json)

    create = post

    def delete(self, setting_key):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        existing_query = {'user_id': user_id, 'setting_key': setting_key}

        self.table.remove(existing_query)
        return ""

    def put(self):
        un, user_id = self.session_user()
        if not un:
            return plz_can_haz_auth()

        # TODO: can user update record?
        request.json['user_id'] = user_id
        setting_key = request.json.get('setting_key')

        existing_query = {'user_id': user_id, 'setting_key': setting_key}

        self.table.remove(existing_query)
        self.table.insert({ 'user_id': user_id
                          , 'setting_key': setting_key
                          , 'setting_value': request.json.get('setting_value')
                          })

        return mongodoc_jsonify(data=request.json)

settings_view = SettingsAPI.as_view('settings_api')

blueprint.add_url_rule( '/user/settings/'
                      , view_func=settings_view
                      , methods=['GET',]
                      )

blueprint.add_url_rule( '/user/settings/'
                      , view_func=settings_view
                      , methods=['POST', 'PUT']
                      )

