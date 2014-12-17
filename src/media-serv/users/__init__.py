""" This is the users module blueprint.
"""
from flask import Blueprint

blueprint = Blueprint('users', __name__)

from views import *
from scores import *
from client_logging import *
