from flask import Blueprint

blueprint = Blueprint('users', __name__)

from views import *

