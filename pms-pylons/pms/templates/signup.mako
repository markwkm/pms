# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">Sign up!</%def>
    <h1>Welcome!</h1>

    ${h.form(h.url(controller='account', action='create'), method='post')}
      <table>
        <tr>
          <td align="right">Login:</td>
          <td>${h.text('login')}</td>
        </tr>
        <tr>
          <td align="right">Email:</td>
          <td>${h.text('email')}</td>
        </tr>
        <tr>
          <td align="right">First Name:</td>
          <td>${h.text('first')}</td>
        </tr>
        <tr>
          <td align="right">Last Name:</td>
          <td>${h.text('last')}</td>
        </tr>
        <tr>
          <td align="right">Password:</td>
          <td>${h.password('password1')}</td>
        </tr>
        <tr>
          <td align="right">Verify Password:</td>
          <td>${h.password('password2')}</td>
        </tr>
      </table>
      ${h.submit('submit', 'Sign up!')}
    ${h.end_form()}
