import logging

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from webhelpers.paginate import Page

from pms.lib.base import BaseController, render

from pms.model.meta import Session
from pms.model.patch import Patch
from pms.model.user import User

log = logging.getLogger(__name__)

class DeveloperController(BaseController):

    requires_auth = ['show']

    def show(self):
        try:
            c.page = request.params['page']
        except:
            c.page = 1

        q = Session.query(User)
        q = q.filter(User.login==session['user'])
        c.user = q.one()

        q = Session.query(Patch)
        q = q.filter(Patch.user_id==c.user.id)
        c.patches = Page(q.all(), page=c.page, items_per_page=10)

        return render('/developer.mako')
