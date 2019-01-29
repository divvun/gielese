# -*- coding: utf-8 -*-
""" This module initializes the database.
"""

from flask.ext.sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from lexicon_models import *
from session_models import *

