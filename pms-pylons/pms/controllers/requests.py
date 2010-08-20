import logging

try:
    import json
except ImportError:
    import simplejson as json

from base64 import b64encode
from re import match, search

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pms.model.meta import Session

from pms.lib.base import BaseController, render

from pms.model.filter import Filter
from pms.model.filter_request import FilterRequest
from pms.model.filter_type import FilterType

from sqlalchemy import update

from bz2 import decompress

log = logging.getLogger(__name__)

class RequestsController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""
    # To properly map this controller, ensure your config/routing.py
    # file has a resource setup:
    #     map.resource('request', 'requests')

    def index(self, format='html'):
        """GET /requests: All items in the collection"""

        types = list()
        for type in request.params.getall('type'):
            types.append(type)

        q3 = Session.query(FilterType.id)
        q3 = q3.filter(FilterType.code.in_(types))

        q2 = Session.query(Filter.id)
        q2 = q2.filter(Filter.filter_type_id.in_(q3))

        q = Session.query(FilterRequest)
        q = q.filter(FilterRequest.filter_id.in_(q2))
        q = q.filter(FilterRequest.state=='Queued')

        # FIXME: Flatten this 3 level query.
        req = q.first()

        # FIXME: Turn this into a single query as opposed to several individual
        # queries that SQLAlchemy will run when using the relationship.
        r = dict()
        if req is not None:
            r['id'] = req.id
            r['patch_id'] = req.patch_id
            r['filter_id'] = req.filter_id
            r['filename'] = req.filter.filename
            r['runtime'] = req.filter.runtime
            r['software'] = req.filter.software.name

        return json.dumps(r)

    def create(self):
        """POST /requests: Create a new item"""
        # url('requests')

    def new(self, format='html'):
        """GET /requests/new: Form to create a new item"""
        # url('new_request')

    def update(self, id):
        """PUT /requests/id: Update an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="PUT" />
        # Or using helpers:
        #    h.form(url('request', id=ID),
        #           method='put')
        # url('request', id=ID)

        # FIXME: Do the UPDATE without doing a SELECT first.
        q = Session.query(FilterRequest)
        q = q.filter(FilterRequest.id==request.POST['id'])
        filter_request = q.one()
        # FIXME: Handle filter request not found.

        filter_request.state = request.POST['state']
        if request.POST['state'] == 'Completed':
            m = match(r'RESULT: (\w+)', request.POST['result'])
            filter_request.result = m.group(1)

            m = search(r'RESULT-DETAIL: (.+)$', request.POST['result'])
            filter_request.result_detail = m.group(1)

            filter_request.output = b64encode(request.POST['result_detail'])
        Session.commit()

    def delete(self, id):
        """DELETE /requests/id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('request', id=ID),
        #           method='delete')
        # url('request', id=ID)

    def show(self, id, format='html'):
        """GET /requests/id: Show a specific item"""
        # url('request', id=ID)
        data = dict()
        data['wow'] = 'sir'
        data['pop'] = 'fry'
        return json.dumps(data)

    def edit(self, id, format='html'):
        """GET /requests/id/edit: Form to edit an existing item"""
        # url('edit_request', id=ID)
