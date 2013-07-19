from . import plz_can_haz_auth

__all__ = [
    'api_login_required',
    'login_required'
]

def api_login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not 'username' in session:
            return plz_can_haz_auth()
        return f(*args, **kwargs)
    return decorated_function

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not 'username' in session:
            return redirect(url_for('user_login', next=request.url))
        return f(*args, **kwargs)
    return decorated_function
