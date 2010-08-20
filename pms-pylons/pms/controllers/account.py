from hashlib import sha1
from time import time

import logging

from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from pylons.decorators import validate

from pms.lib.base import BaseController, render

from pms.model.form import SignupForm
from pms.model.meta import Session
from pms.model.user import User

log = logging.getLogger(__name__)

class AccountController(BaseController):

    def authenticate(self):
        m = sha1()
        m.update(str(request.POST.get('password')))
        m.update(config['password.salt'])

        q = Session.query(User)
        q = q.filter(User.login == str(request.POST.get('login')))
        q = q.filter(User.password == m.hexdigest())
        try:
            user = q.one()
        except NoResultFound:
            return render('/login.mako')
        except:
            return redirect('/account/error')

        session['user'] = user.login
        session['session_timeout'] = user.login
        session.save()
        redirect(session['path_before_login'])

    @validate(schema=SignupForm(), form='signup')
    def create(self):
        # Salt the password.
        m = sha1()
        m.update(str(request.POST['password1']))
        m.update(config['password.salt'])

        # Insert the user information into the database.
        user = User()
        user.login = request.POST['login']
        user.password = m.hexdigest()
        user.email = request.POST['email']
        user.first = request.POST['first']
        user.last = request.POST['last']
        Session.add(user)
        Session.commit()

        # Set the session state such that this user is now logged in.
        session['user'] = user.login
        session.save()

        q = Session.query(User)
        q = q.filter(User.login==user.login)
        user = q.one()
        return redirect('/developer/show/%d' % user.id)

    def error(self):
        return 'application error'

    def login(self):
        if 'path_before_login' not in session or \
                session['path_before_login'] == '/account/login':
            # Go to the user's personal page if there is nowhere else to
            # redirect to.
            session['path_before_login'] = '/developer/show'
            session.save()
        return render('/login.mako')

    def logout(self):
        if 'user' in session:
            session.pop('user')
            session.pop('path_before_login')
            session.save()
        return redirect('/')

    def signup(self):
        return render('/signup.mako')
