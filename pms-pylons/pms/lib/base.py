"""The base Controller API

Provides the BaseController class for subclassing.
"""
from time import time

from pylons import config, request, session
from pylons.controllers import WSGIController, XMLRPCController
from pylons.controllers.util import redirect
from pylons.templating import render_mako as render

from pms.model.meta import Session

class BaseController(WSGIController):

    requires_auth = []

    def __before__(self, action):
        if 'user' in session and 'session.timestamp' in session:
            diff = time() - session['session.timestamp']
            if diff > config['session.timeout']:
                # Session timed out, redirect to login page.
                return redirect('/account/login')

        if action in self.requires_auth and 'user' not in session:
            # Authentication required.
            session['path_before_login'] = request.path_info
            session['session.timestamp'] = time()
            session.save()
            return redirect('/account/login')

        session['session.timestamp'] = time()
        session.save()

    def __call__(self, environ, start_response):
        """Invoke the Controller"""
        # WSGIController.__call__ dispatches to the Controller method
        # the request is routed to. This routing information is
        # available in environ['pylons.routes_dict']
        try:
            return WSGIController.__call__(self, environ, start_response)
        finally:
            Session.remove()
