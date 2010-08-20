import logging

from base64 import b64decode

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pms.lib.base import BaseController, render

from pms.model.meta import Session
from pms.model.filter_request import FilterRequest

log = logging.getLogger(__name__)

class FilterRequestController(BaseController):

    def output(self, id):
        q = Session.query(FilterRequest.output)
        filter_request = q.filter(FilterRequest.id==int(id)).one()
        c.output = b64decode(str(filter_request.output))
        return render('/output.mako')
