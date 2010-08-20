import logging

from gzip import GzipFile
from bz2 import compress, decompress

from base64 import b64decode, b64encode

from pylons import request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from pylons.decorators import validate

from webhelpers.paginate import Page

from mimetypes import guess_type

from sqlalchemy import or_

from pms.lib.base import BaseController, render

from pms.model.form import PatchForm
from pms.model.meta import Session
from pms.model.filter import Filter
from pms.model.filter_request import FilterRequest
from pms.model.patch import Patch
from pms.model.software import Software
from pms.model.user import User

log = logging.getLogger(__name__)

class PatchController(BaseController):

    requires_auth = ['create', 'new'] 

    @validate(schema=PatchForm(), form='new')
    def create(self):
        user = Session.query(User).filter(User.login==session['user']).one()

        q = Session.query(Patch)
        q = q.filter(Patch.name==request.POST['applies_name'])
        applies = q.one()

        if request.POST['diff'].type == 'text/plain' or \
           request.POST['diff'].type == 'application/octet-stream':
            diff = b64encode(request.POST['diff'].value)
        elif request.POST['diff'].type == 'application/x-gzip':
            output = GzipFile(mode='rb', fileobj=request.POST['diff'].file)
            diff = b64encode(output.read())
            output.close()
        elif request.POST['diff'].type == 'application/x-bzip2':
            diff = b64encode(decompress(request.POST['diff'].value))
        else:
            log.error('Unknown type: %s' % request.POST['diff'].type)
        # FIXME: Handle unknown file types.

        patch = Patch()
        patch.user_id = user.id
        patch.patch_id = applies.id
        patch.software_id = request.POST['software_id']
        patch.name = request.POST['name']
        patch.diff = diff
        patch.remote_identifier = request.POST['diff'].filename
        patch.strip_level = request.POST['strip_level']
        if 'reverse' in request.POST:
            patch.reverse = True
        else:
            patch.reverse = False
        Session.add(patch)
        Session.commit()

        # FIXME: I think this next bit to set create filter requests for a
        # newly submitted patch is more efficiently done with a 'INSERT INTO
        # ...  SELECT ...' kind of statement.
        q = Session.query(Filter)
        q = q.filter(or_(Filter.software_id == 0,
                         Filter.software_id == patch.software_id))
        filters = q.all()
        for filter in filters:
            filter_request = FilterRequest()
            filter_request.filter_id = filter.id
            filter_request.patch_id = patch.id
            filter_request.state = 'Queued'
            filter_request.priority = 1
            filter_request.updated_on = 'now()'
            Session.add(filter_request)
            Session.commit()

        return redirect('/developer/show')

    def download(self, id):
        q = Session.query(Patch)
        q = q.filter(Patch.id==id)
        patch = q.one()

        diff = compress(b64decode(str(patch.diff)))

        response.headers['Content-type'] = 'application/octet-stream'
        response.headers['Content-Disposition'] = \
                'attachment; filename=%s.bz2' % patch.remote_identifier
        response.headers['Accept-Ranges'] = 'bytes'
        response.headers['Content-Length'] = len(diff)
        response.headers['Content-Transfer-Encoding'] = 'binary'
        return diff

    def new(self):
        # Build a list for the webhelper select method.
        q = Session.query(Software)
        softwares = q.all()
        c.software = list()
        for software in softwares:
            c.software.append([software.id, software.name])

        return render('/patch_new.mako')

    def search(self):
        # Build a list for the webhelper select method.
        q = Session.query(Software)
        softwares = q.all()
        c.software = list()
        c.software.append(['', ''])
        for software in softwares:
            c.software.append([software.id, software.name])

        return render('/search.mako')

    # FIXME: How to use named parameters with PostgreSQL INTERVAL.
    def search_result(self):
        # Save form data to the server side session structure for the
        # paginator.  Identify we got here from the search form based on
        # whether there is a 'submit' parameter used.
        if 'submit' in request.POST and request.POST['submit'] == \
                                       'Submit Query':
            session['s_identifier'] = request.POST['identifier']
            session['s_software_id'] = request.POST['software_id']
            session['s_user_name'] = request.POST['user_name']
            #session['s_created'] = request.POST['created']
            session.save()

        q = Session.query(Patch)
        if len(session['s_identifier']) > 0:
            q = q.filter(Patch.name.ilike('%%%s%%' %
                                          session['s_identifier']))
        #if len(session['s_created']) > 0:
            #q = q.filter(Patch.created_on > 'NOW() - INTERVAL %s' %
                                             #request.POST['created'])
        if len(session['s_software_id']) > 0:
            q = q.filter(Patch.software_id==int(session['s_software_id']))
        if len(session['s_user_name']) > 0:
            q2 = Session.query(User.id)
            q2 = q2.filter(or_(User.first.ilike('%%%s%%' %
                                                session['s_user_name']),
                               User.last.ilike('%%%s%%' %
                                                session['s_user_name']),
                               User.login.ilike('%%%s%%' %
                                                session['s_user_name']),
                               User.email.ilike('%%%s%%' %
                                                session['s_user_name'])))
            # FIXME: Flatten this subquery.
            q = q.filter(Patch.user_id.in_(q2))

        try:
            c.page = request.params['page']
        except:
            c.page = 1
        c.patches = Page(q.all(), page=c.page, items_per_page=10)
        return render('/results.mako')

    def show(self, id):
        q = Session.query(Patch)
        q = q.filter(Patch.id==id)
        c.patch = q.one()

        return render('/patch.mako')

    def view(self, id):
        q = Session.query(Patch)
        q = q.filter(Patch.id==id)
        c.patch = q.one()

        c.diff = b64decode(str(c.patch.diff))

        return render('/patch_view.mako')
