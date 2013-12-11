from . import blueprint
from flask import current_app

from bson import ObjectId
from datetime import datetime, timedelta
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

from schematics.models import Model
from schematics.types import EmailType, StringType
from schematics.exceptions import ValidationError

from itsdangerous import ( TimestampSigner
                         , URLSafeTimedSerializer
                         , TimedSerializer
                         , BadSignature
                         , BadData
                         , SignatureExpired
                         )

# TODO: @auth_required views

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

    class LoginFormValidator(Model):
        username = StringType(required=True)
        password = StringType(required=True)

    form = LoginFormValidator(request.form.to_dict())

    try:
        form.validate()
    except ValidationError, e:
        return nopes("Validation error(s)", e.messages)

    user = form.username
    pw = form.password

    # TODO: switch this to a validator
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

@blueprint.route('/user/reset/', methods=['POST'])
def reset():
    # mongodb tables needed
    users = current_app.mongodb.db.users
    reset_tokens = current_app.mongodb.db.reset_tokens
    reset_log = current_app.mongodb.db.reset_log

    # set this here for validation
    requester_ip = request.remote_addr

    # signature validation
    dangerous_unserializer = URLSafeTimedSerializer(current_app.secret_key)

    def token_is_valid(value):
        """ This unsigns the reset token, and checks the signature. In
        addition, in order to prevent someone from resetting their
        password more than once, the token is checked against currently
        issued tokens, if it is not found, then the token has been used.
        """

        decoded_payload = None

        try:
            decoded_payload = dangerous_unserializer.loads(value,
                                                           max_age=60*60*3)
            # This payload is decoded and safe
        except SignatureExpired, e:
            raise ValidationError("The token has expired.")
        except BadSignature, e:
            encoded_payload = e.payload
            if encoded_payload is not None:
                try:
                    decoded_payload = dangerous_unserializer.load_payload(encoded_payload)
                except BadData:
                    raise ValidationError("The signature was tampered with.")
                    return False
            # This payload is decoded but unsafe and has been tampered
            # with.

        if reset_tokens.find({ 'token': form.token }).count() == 0:
            raise ValidationError("The token is no longer usable.")

        return decoded_payload

    class PasswordResetValidator(Model):
        token = StringType(required=True, validators=[token_is_valid])

        new_password = StringType(required=True)
        repeat_password = StringType(required=True)

        def validate_new_password(self, data, value):
            """ This unsigns the reset token, and checks the signature. In
            addition, in order to prevent someone from resetting their
            password more than once, the token is checked against currently
            issued tokens, if it is not found, then the token has been used.
            """
            if data.get('new_password') != data.get('repeat_password'):
                raise ValidationError("Passwords do not match.")
            return value

    form = PasswordResetValidator(request.form.to_dict())

    try:
        form.validate()
    except ValidationError, e:
        return nopes("Validation error(s)", e.messages)

    username = dangerous_unserializer.loads(form.token)
    new_password = form.new_password

    # once user has reset the password, the token needs to be expired
    # otherwise they'll be able to reset endlessly, which is fine, but
    # may cause problems for them, or imply that someone watching has
    # intercepted the request and has attempted to replay it.

    reset_tokens.remove({ 'token': form.token })

    u = users.find_one({'username': username})
    email = u.get('email')

    u.update({
        'password': pwd_context.encrypt(new_password),
    })

    # Also log the successful reset.

    reset_log.insert({ 'email': email
                     , 'requester_ip': requester_ip
                     , 'request_type': 'password_reset_success'
                     , 'datetime': datetime.now()
                     })

    return nope({"success": True})


# TODO: validate, check that user exists, if not, nope
@blueprint.route('/user/forgot/', methods=['POST'])
def forgot():
    dangerous_signer = URLSafeTimedSerializer(current_app.secret_key)

    # http://pythonhosted.org/itsdangerous/
    # app.secret_key
    # TODO: s.unsign(string, max_age=60)

    from flask import jsonify

    users = current_app.mongodb.db.users
    reset_log = current_app.mongodb.db.reset_log
    reset_tokens = current_app.mongodb.db.reset_tokens

    requester_ip = request.remote_addr

    def nope(error):
        return Response( simplejson.dumps(dict(error=error))
                       , status=500
                       , mimetype='application/json'
                       )

    def email_does_not_exist(value):
        if not users.find_one({'email': value}):
            raise ValidationError("This email does not exist.")
        return value

    def not_spamming(value):
        # check that this hasn't been registered several times in the
        # past 20 minutes

        return value

    # TODO: validate
    class UserForgotValidation(Model):
        email_address = EmailType(required=True,
                                  validators=[email_does_not_exist,
                                              not_spamming])

    form = UserForgotValidation(request.form.to_dict())

    try:
        form.validate()
    except ValidationError, e:
        return nopes("Validation error(s)", e.messages)

    email = request.form['email_address']

    # The form will all be valid here

    u = users.find_one({'email': email})
    print "Reset request received for %s" % repr(u)

    reset_token = dangerous_signer.dumps(u.get('username'))

    # log IP, and target email-- this will be used in validation of
    # future requests

    reset_log.insert({ 'email': email
                     , 'requester_ip': requester_ip
                     , 'request_type': 'email_submit'
                     , 'datetime': datetime.now()
                     })

    # If user already has a token out, need to delete those first so
    # that a new one is issued.
    reset_tokens.remove({'email': email})

    # expiration is encoded in the token
    reset_tokens.insert({ 'email': email
                        , 'token': reset_token
                        })

    print "reset token is %s" % reset_token

    # TODO: send the email

    return jsonify({'success': True})



@blueprint.route('/user/create/', methods=['POST', 'CREATE'])
def create_user():
    # TODO: send confirmation email

    def user_does_not_exist(value):
        if users.find_one({'username': value}):
            raise ValidationError("exists")
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

    form = UserFormValidation(request.form.to_dict())

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

    return jsonify(success=True)

@blueprint.route('/user/logout/')
def logout():
    # remove the username from the session if it's there

    # TEST:
    # http -f POST http://localhost:5000/user/create/ username=boba password=bobbala email=boba@someplace.com
    # http -f POST http://localhost:5000/user/login/ username=boba password=bobbala --session=boba
    # http GET http://localhost:5000/user/data/log/ --session=boba
    # http GET http://localhost:5000/user/logout/ --session=boba
    # http GET http://localhost:5000/user/data/log/ --session=boba

    # TODO: session not invalidating
    session.clear()
    print help(session)
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

