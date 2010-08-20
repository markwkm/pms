import logging

try:
    import json
except ImportError:
    import simplejson as json

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pms.model.meta import Session

from pms.lib.base import BaseController, render

from pms.model.patch import Patch
log = logging.getLogger(__name__)

class PsController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""
    # To properly map this controller, ensure your config/routing.py
    # file has a resource setup:
    #     map.resource('p', 'ps')

    def index(self, format='html'):
        """GET /ps: All items in the collection"""
        # url('ps')

    def create(self):
        """POST /ps: Create a new item"""
        # url('ps')

    def new(self, format='html'):
        """GET /ps/new: Form to create a new item"""
        # url('new_p')

    def update(self, id):
        """PUT /ps/id: Update an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="PUT" />
        # Or using helpers:
        #    h.form(url('p', id=ID),
        #           method='put')
        # url('p', id=ID)

    def delete(self, id):
        """DELETE /ps/id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('p', id=ID),
        #           method='delete')
        # url('p', id=ID)

    def show(self, id, format='html'):
        """GET /ps/id: Show a specific item"""
        q = Session.query(Patch.remote_identifier, Patch.path, Patch.source_id,
                          Patch.reverse, Patch.strip_level, Patch.diff,
                          Patch.name, Patch.patch_id)
        q = q.filter(Patch.id==id)
        patch = q.one()
        # FIXME: Is there a better way to serialize a SQLAlchemy Result Object.
        r = dict()
        r['name'] = patch.name
        r['remote_identifier'] = patch.remote_identifier
        r['path'] = patch.path
        r['source_id'] = patch.source_id
        r['reverse'] = patch.reverse
        r['strip_level'] = patch.strip_level
        r['patch_id'] = patch.patch_id
        return json.dumps(r)

    def edit(self, id, format='html'):
        """GET /ps/id/edit: Form to edit an existing item"""
        # url('edit_p', id=ID)
