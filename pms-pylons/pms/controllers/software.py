import logging

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from pms.lib.base import BaseController, render

from pms import model

log = logging.getLogger(__name__)

class SoftwareController(BaseController):
    """REST Controller styled on the Atom Publishing Protocol"""
    # To properly map this controller, ensure your config/routing.py
    # file has a resource setup:
    #     map.resource('software', 'softwares')

    def index(self, format='html'):
        """GET /softwares: All items in the collection"""
        # url('softwares')
        software_q = model.meta.Session.query(model.Software)
        c.softwares = software_q.all()
        return render('/softwares/index.html')

    def create(self):
        """POST /softwares: Create a new item"""
        # url('softwares')

    def new(self, format='html'):
        """GET /softwares/new: Form to create a new item"""
        # url('new_software')

    def update(self, id):
        """PUT /softwares/id: Update an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="PUT" />
        # Or using helpers:
        #    h.form(url('software', id=ID),
        #           method='put')
        # url('software', id=ID)

    def delete(self, id):
        """DELETE /softwares/id: Delete an existing item"""
        # Forms posted to this method should contain a hidden field:
        #    <input type="hidden" name="_method" value="DELETE" />
        # Or using helpers:
        #    h.form(url('software', id=ID),
        #           method='delete')
        # url('software', id=ID)

    def show(self, id, format='html'):
        """GET /softwares/id: Show a specific item"""
        # url('software', id=ID)
        software_q = model.meta.Session.query(model.Software)
        c.software = software_q.filter(model.Software.name==id)[0]
        return render('/softwares/show.html')

    def edit(self, id, format='html'):
        """GET /softwares/id/edit: Form to edit an existing item"""
        # url('edit_software', id=ID)
