from . import blueprint

from bson import ObjectId
from datetime import datetime, timedelta

from textwrap import dedent
from flask.ext.babel import gettext as _

from flask import Response, session, jsonify, request
from flask import current_app, render_template
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

    def length_is_greater(value):
        if len(value) < 7:
            raise ValidationError("Your password must be at least 8 characters.")
        return value

    class LoginFormValidator(Model):
        username = StringType(required=True)
        password = StringType(required=True, validators=[length_is_greater])

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
        else:
            return nope('You were not authenticated.')

    return nope('You were not authenticated.')

@blueprint.route('/user/reset/form/', methods=['GET'])
def reset_form():
    """
    ..  http:get::
              /user/reset/

        GET produces a form. This requires a cryptographic key in HTTP
        parameters to generate the form. Here we just check that the key
        is valid, and do not consume it.

        TODO: prevent brute forcing by tracking IPs, if too many invalid
        tokens submitted, block

        :param token: the cryptographic key
    """
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

        TOKEN_EXPIRED_ERROR = _(dedent(
            """ You waited too long to reset your password. Please
            request to have it reset again, and make sure you complete
            this in three hours.  """
        ))

        TOKEN_TAMPERED = _(dedent("The token was tampered with."))


        try:
            decoded_payload = dangerous_unserializer.loads(value,
                                                           max_age=60*60*3)
            # This payload is decoded and safe
        except SignatureExpired, e:
            raise ValidationError(TOKEN_EXPIRED_ERROR)
        except BadSignature, e:
            encoded_payload = e.payload
            if encoded_payload is not None:
                try:
                    decoded_payload = dangerous_unserializer.load_payload(encoded_payload)
                except BadData:
                    raise ValidationError(TOKEN_TAMPERED)
                    return False
            # This payload is decoded but unsafe and has been tampered
            # with.

        if reset_tokens.find({ 'token': form.token }).count() == 0:
            raise ValidationError(TOKEN_EXPIRED_ERROR)

        return decoded_payload

    class FollowedLinkValidator(Model):
        token = StringType(required=True, validators=[token_is_valid])

    form = FollowedLinkValidator(request.args.to_dict())

    context = {}

    try:
        form.validate()
    except ValidationError, e:
        context['errors'] =  e.messages

    username = dangerous_unserializer.loads(form.token)

    context['username'] = username
    context['token'] = form.token

    return render_template('user_reset_form.html', **context)

@blueprint.route('/user/reset/', methods=['POST'])
def reset():
    """
    .. http:post::
              /user/reset/

        POST a form to this address. This requires a valid cryptographic
        key, which hasn't yet expired as far as the MongoDB store is
        concerned, and the date that the key was signed on.

        If the token is used once to reset a password, it is removed
        from the store.

        TODO: password length validation

        :param token: the cryptographic key
        :param new_password: the new password
        :param repeat_password: a repeat.

        :returns:
            JSON with {'success': True} or {'success': False}

    """
    # mongodb tables needed
    users = current_app.mongodb.db.users
    reset_tokens = current_app.mongodb.db.reset_tokens
    reset_log = current_app.mongodb.db.reset_log

    # set this here for validation
    requester_ip = request.remote_addr

    # signature validation
    dangerous_unserializer = URLSafeTimedSerializer(current_app.secret_key)

    def length_is_greater(value):
        if len(value) < 7:
            raise ValidationError("Your password must be at least 8 characters.")
        return value

    def token_is_valid(value):
        """ This unsigns the reset token, and checks the signature. In
        addition, in order to prevent someone from resetting their
        password more than once, the token is checked against currently
        issued tokens, if it is not found, then the token has been used.
        """

        decoded_payload = None

        TOKEN_EXPIRED_ERROR = _(dedent(
            """ You waited too long to reset your password. Please
            request to have it reset again, and make sure you complete
            this in three hours.  """
        ))

        TOKEN_TAMPERED = _(dedent("The token was tampered with."))

        try:
            decoded_payload = dangerous_unserializer.loads(value,
                                                           max_age=60*60*3)
            # This payload is decoded and safe
        except SignatureExpired, e:
            raise ValidationError(TOKEN_EXPIRED_ERROR)
        except BadSignature, e:
            encoded_payload = e.payload
            if encoded_payload is not None:
                try:
                    decoded_payload = dangerous_unserializer.load_payload(encoded_payload)
                except BadData:
                    raise ValidationError(TOKEN_TAMPERED)
                    return False
            # This payload is decoded but unsafe and has been tampered
            # with.

        if reset_tokens.find({ 'token': form.token }).count() == 0:
            raise ValidationError(TOKEN_EXPIRED_ERROR)

        return decoded_payload

    class PasswordResetValidator(Model):
        token = StringType(required=True, validators=[token_is_valid])

        new_password = StringType(required=True, validators=[length_is_greater])
        repeat_password = StringType(required=True, validators=[length_is_greater])

        def validate_new_password(self, data, value):
            """ This unsigns the reset token, and checks the signature. In
            addition, in order to prevent someone from resetting their
            password more than once, the token is checked against currently
            issued tokens, if it is not found, then the token has been used.
            """
            if data.get('new_password') != data.get('repeat_password'):
                raise ValidationError(_("Passwords do not match."))
            return value

    content_type = request.headers.get('Content-Type')

    if 'json' in content_type:
        json = True
        input_data = request.json
    else:
        json = False
        input_data = request.form.to_dict()

    form = PasswordResetValidator(input_data)
    context = {}
    context['token'] = form.token

    try:
        form.validate()
    except ValidationError, e:
        if json:
            return nopes("Validation error(s)", e.messages)
        else:
            context['errors'] = e.messages

    username = dangerous_unserializer.loads(form.token)
    new_password = form.new_password

    context['username'] = username

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
    users.save(u)

    # Also log the successful reset.

    reset_log.insert({ 'email': email
                     , 'requester_ip': requester_ip
                     , 'request_type': 'password_reset_success'
                     , 'datetime': datetime.now()
                     })

    if json:
        return nope({"success": True})
    else:
        if not 'errors' in context:
            context['success'] = True
        else:
            context['success'] = False
        return render_template('user_reset_form.html', **context)

from flask_marrowmailer import Mailer

# TODO: validate, check that user exists, if not, nope
@blueprint.route('/user/forgot/', methods=['POST'])
def forgot():
    """
    .. http:post::
              /user/forgot/

        POST JSON to this address with one of the following parameters.
        This will generate an email to be sent to the user, with a
        cryptographically signed token that is valid for a few hours,
        and usable once.

        The token is signed for the date that it was produced, but is
        also set in a MongoDB store and removed when used.

        The view also tracks submission requests to prevent abuse.

        TODO: generate the actual email
        TODO: include abuse in validation functions.
        TODO: accept username or email

        :param email: the user's email address
        :param username: the target language

        :returns:
            JSON with {'success': True} or {'success': False}

    """
    dangerous_signer = URLSafeTimedSerializer(current_app.secret_key)

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
            raise ValidationError(_("This email does not exist."))
        return value

    def username_exists(value):
        if not users.find_one({'username': value}):
            raise ValidationError(_("This username does not exist."))
        return value

    def not_spamming(value):
        # check that this hasn't been registered several times in the
        # past 20 minutes

        return value

    # TODO: validate
    class UserForgotValidation(Model):
        username = StringType(validators=[username_exists,
                                         not_spamming])
        email_address = EmailType(required=False,
                                  validators=[email_does_not_exist,
                                              not_spamming])


    form = UserForgotValidation(request.form.to_dict())

    try:
        form.validate()
    except ValidationError, e:
        return nopes("Validation error(s)", e.messages)

    email = request.form.get('email_address', False)
    username = request.form.get('username', False)

    # The form will all be valid here

    if email:
        u = users.find_one({'email': email})
    elif username:
        u = users.find_one({'username': username})

    reset_token = dangerous_signer.dumps(u.get('username'))
    email = u.get('email')

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

    # TODO: internationalize
    reset_link = 'http://gielese.no/user/reset/form/?token=%s' % reset_token
    # TODO: put this in a config
    reply_address = current_app.config.services.mail.reply_address

    msg = current_app.mailer.new()
    msg.author = current_app.config.services.mail.author
    msg.to = [email]
    msg.subject = 'Reset your password'
    msg.render_template(
        'forgot_password_email',
        reset_link=reset_link,
        reply_address=reply_address)

    if not current_app.debug:
        current_app.mailer.send(msg)
    else:
        print msg
        print '--'
        print reset_link

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

    def length_is_greater(value):
        if len(value) < 7:
            raise ValidationError("Your password must be at least 8 characters.")
        return value

    class UserFormValidation(Model):
        username = StringType(required=True, validators=[user_does_not_exist])
        password = StringType(required=True, validators=[length_is_greater])
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

    # TODO: session not invalidating?
    session.pop('username', None)
    return jsonify(success=True)

@blueprint.route('/session/update/', methods=['POST'])
def update_session():
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
def generate_session_token():
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
def get_session():
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

