from flask import Blueprint

blueprint = Blueprint('authentication', __name__)

from views import *
from decorators import *

