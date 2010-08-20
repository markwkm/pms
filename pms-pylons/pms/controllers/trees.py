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

class TreesController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""
    # To properly map this controller, ensure your config/routing.py
    # file has a resource setup:
    #     map.resource('tree', 'trees')

    def index(self, format='html'):
        """GET /trees: All items in the collection"""
        # url('trees')

    def create(self):
        """POST /trees: Create a new item"""
        # url('trees')

    def new(self, format='html'):
        """GET /trees/new: Form to create a new item"""
        # url('new_tree')

    def update(self, id):
        """PUT /trees/id: Update an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="PUT" />
        # Or using helpers:
        #    h.form(url('tree', id=ID),
        #           method='put')
        # url('tree', id=ID)

    def delete(self, id):
        """DELETE /trees/id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('tree', id=ID),
        #           method='delete')
        # url('tree', id=ID)

    def show(self, id, format='html'):
        """GET /trees/id: Show a specific item"""

        # Get the patch's parent id for the first patch.
        count = 0
        q = Session.query(Patch.id, Patch.patch_id)
        q = q.filter(Patch.id==id)
        patch = q.one()
        r = dict()
        r[count] = patch.id

        # Keep iterating until there is no parent patch.
        while patch.patch_id is not None:
            log.debug(patch.patch_id)
            count += 1
            # FIXME: Can we just change the value for the filter than rebuild
            # the query?
            q = Session.query(Patch.id, Patch.patch_id)
            q = q.filter(Patch.id==patch.patch_id)
            patch = q.one()
            r[count] = patch.id

        return json.dumps(r)

    def edit(self, id, format='html'):
        """GET /trees/id/edit: Form to edit an existing item"""
        # url('edit_tree', id=ID)
