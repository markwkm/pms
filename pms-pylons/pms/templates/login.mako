# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">Login</%def>
    <h3>Please Login</h3>

    ${h.form(h.url(controller='account', action='authenticate'), method='post')}
      <p>
        Username: ${h.text('login')}
      </p>
      <p>
        Password: ${h.password('password')}
      </p>
      <p>
        ${h.submit('submit', 'Login')}
      </p>
    ${h.end_form()}
