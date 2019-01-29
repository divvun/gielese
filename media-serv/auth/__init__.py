""" This module handles a variety of authentication from user creation
to password resets.  """

from flask import Blueprint

blueprint = Blueprint('authentication', __name__)

from views import *
from decorators import *
