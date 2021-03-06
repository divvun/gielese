""" This endpoint is for logging javascript errors.
"""

from . import blueprint
from flask import current_app

from flask import Response, session, jsonify, request
from flask import request
from flask.views import MethodView
import simplejson

from .views import SessionCheck


def client_logger():
    import logging
    file_handler = logging.FileHandler('client_log.txt')
    client_log = logging.getLogger('client_log')
    client_log.addHandler(file_handler)
    client_log.setLevel(logging.INFO)
    return client_log

class ClientLoggerAPI(MethodView, SessionCheck):

    @property
    def logger(self):
        if not hasattr(self, '_logger'):
            self._logger = client_logger()
        return self._logger

    def post(self):
        un, user_id = self.session_user()
        if not un:
            un = 'anonymous'

        _uastring = request.headers.get('User-Agent')

        def fmt_log(form):
            import datetime

            # something wrong with timestamps not getting correct year
            def fmt_time(t_str):
                return t_str

            return '\t'.join([
                form.get('logger'),
                fmt_time(form.get('timestamp')),
                "user:" + un,
                form.get('level'),
                _uastring,
                form.get('url'),
                form.get('message'),
            ])

        def get_logger(form):
            _level = form.get('level').lower()
            return getattr(self.logger, _level)

        get_logger(request.form)(
            fmt_log(request.form)
        )

        return Response( simplejson.dumps({'success': True})
                       , mimetype='application/json'
                       )


# Initialize the router
client_log_view = ClientLoggerAPI.as_view('client_logger_api')

blueprint.add_url_rule( '/client_logger/'
                      , defaults={}
                      , view_func=client_log_view
                      , methods=['POST']
                      )
