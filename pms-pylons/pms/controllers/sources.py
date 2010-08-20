import logging

try:
    import json
except ImportError:
    import simplejson as json

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pms.model.meta import Session

from pms.lib.base import BaseController, render

from pms.model.source import Source

log = logging.getLogger(__name__)

class SourcesController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""
    # To properly map this controller, ensure your config/routing.py
    # file has a resource setup:
    #     map.resource('source', 'sources')

    def index(self, format='html'):
        """GET /sources: All items in the collection"""
        # url('sources')

    def create(self):
        """POST /sources: Create a new item"""
        # url('sources')

    def new(self, format='html'):
        """GET /sources/new: Form to create a new item"""
        # url('new_source')

    def update(self, id):
        """PUT /sources/id: Update an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="PUT" />
        # Or using helpers:
        #    h.form(url('source', id=ID),
        #           method='put')
        # url('source', id=ID)

    def delete(self, id):
        """DELETE /sources/id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('source', id=ID),
        #           method='delete')
        # url('source', id=ID)

    def show(self, id, format='html'):
        """GET /sources/id: Show a specific item"""
        q = Session.query(Source.source_type, Source.root_location)
        q = q.filter(Source.id==id)
        source = q.one()
        r = dict()
        r['source_type'] = source.source_type
        r['root_location'] = source.root_location
        return json.dumps(r)

    def edit(self, id, format='html'):
        """GET /sources/id/edit: Form to edit an existing item"""
        # url('edit_source', id=ID)
