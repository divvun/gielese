from . import blueprint
from flask import current_app

from bson import ObjectId
from datetime import datetime
from flask import Response, session, jsonify, request
from flask import request
from flask.views import MethodView
from functools import wraps
import simplejson

from passlib.apps import custom_app_context as pwd_context

def plz_can_haz_auth():
    return Response( simplejson.dumps(dict(error="no login"))
                   , status=401
                   , mimetype='application/json'
                   )


# TODO: actually authenticate
# TODO: @auth_required views
# TODO:

# TODO: validate, check that user exists, if not, nope
@blueprint.route('/user/login/', methods=['POST'])
def login():
    from flask import jsonify
    users = current_app.mongodb.db.users

    def nope(error):
        return Response( simplejson.dumps(dict(error=error))
                       , status=500
                       , mimetype='application/json'
                       )

    # TODO: validate

    user = request.form['username']
    pw = request.form['password']

    u = users.find_one({'username': user})
    if u:
        if pwd_context.verify(pw, u.get('password')):
            session['username'] = request.form['username']
            u_data = u.copy()
            u_data.pop('password')
            u_data.pop('_id')
            print u_data
            return jsonify(user=u_data)

    return nope('You were not authenticated.')

@blueprint.route('/user/create/', methods=['POST', 'CREATE'])
def create_user():
    from schematics.models import Model
    from schematics.types import EmailType, StringType
    from schematics.exceptions import ValidationError
    from schematics.serialize import blacklist

    def user_does_not_exist(value):
        if users.find_one({'username': value}):
            raise ValidationError("User with that name exists already!")
        return value

    def email_does_not_exist(value):
        if users.find_one({'email': value}):
            raise ValidationError("This email is in use already, please use another.")
        return value


    class UserFormValidation(Model):
        username = StringType(required=True, validators=[user_does_not_exist])
        password = StringType(required=True)
        email = EmailType(required=True, validators=[email_does_not_exist])

    users = current_app.mongodb.db.users

    def nope(error):
        return Response( simplejson.dumps(dict(error=error))
                       , status=500
                       , mimetype='application/json'
                       )

    def nopes(error, reasons):
        return Response( simplejson.dumps(dict(error=error, reasons=reasons))
                       , status=500
                       , mimetype='application/json'
                       )

    print request.form
    form = UserFormValidation(**request.form.to_dict())

    try:
        form.validate()
    except ValidationError, e:
        return nopes("Validation error(s)", e.messages)

    un = form.username
    pw = form.password
    em = form.email

    user_kwargs = { 'username': un
                  , 'password': pwd_context.encrypt(pw)
                  , 'email': em
                  }


    # remove the username from the session if it's there
    session.pop('username', None)
    users.insert(user_kwargs)

    print list(users.find())

    return jsonify(success=True)

@blueprint.route('/user/logout/')
def logout():
    # remove the username from the session if it's there
    # TODO: doesn't seem to kill the cookie 

    # TEST:
    # http -f POST http://localhost:5000/user/create/ username=boba password=bobbala email=boba@someplace.com
    # http -f POST http://localhost:5000/user/login/ username=boba password=bobbala --session=boba
    # http GET http://localhost:5000/user/data/log/ --session=boba
    # http GET http://localhost:5000/user/logout/ --session=boba
    # http GET http://localhost:5000/user/data/log/ --session=boba

    session.pop('username', None)
    return jsonify(success=True)

@blueprint.route('/session/update/', methods=['POST'])
def generate_session():
    from session_models import Session

    # TODO: get user id, user access token from form

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    # get data from form, encode to string, and save session
    user_data = json.loads(request.form.get('user_data', False))

    # TODO: validate

    session.data = json.dumps(user_data)

    # TODO: TEST, right function, does it work?
    db.session.merge(session)

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False

@blueprint.route('/session/token/', methods=['POST'])
def generate_session():
    from session_models import Session

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False

@blueprint.route('/session/get/', methods=['POST'])
def generate_session():
    from session_models import Session

    user_id = request.form.get('user_id', False)
    access_token = request.form.get('access_token', False)

    session = db.session.query(Session).filter(
        and_( Session.user_id == user_id
            , Session.access_token == access_token
            )
    )

    if len(session) > 0:
        session = session[0]
        return json.dumps({ 'user_id': session.user_id.hex
                          , 'user_data': json.loads(session.data),
                          })
    else:
        return False


@blueprint.route('/session/generate/', methods=['GET'])
def generate_session():
    import uuid
    from session_models import Session

    _add = db.session.add

    user_id = uuid.uuid4()
    access_token = uuid.uuid4()

    sess = Session(user_id=user_id.hex, access_token=access_token.hex)
    _add(sess)

    return json.dumps({
        'user_id': user_id.hex,
        'access_token': access_token.hex,
    })

