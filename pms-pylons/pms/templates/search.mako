# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">Search</%def>
    <h1>Search</h1>

    ${h.form(h.url(controller='patch', action='search_result'), method='post')}

    <table>
      <tr>
        <td>Software Repository</td>
        <td>${h.select('software_id', '', c.software)}</td>
      </tr>
      <tr>
        <td>Patch Name</td>
        <td>${h.text('identifier')}</td>
      </tr>
      <tr>
        <td>User Name</td>
        <td>${h.text('user_name')}</td>
      </tr>
<!-- Comment out until we figure out how to use parameters with PostgreSQL INVTERVALE and SQLAlchemy.
      <tr>
        <td>Created</td>
        <td>
          <select name="created">
            <option selected="selected" value=""></option>
            <option value="24 hours">Last 24 Hours</option>
            <option value="7 days">Last 7 Days</option>
            <option value="30 days">Last 30 Days</option>
            <option value="3 months">Last 3 Months</option>
            <option value="6 months">Last 6 Months</option>
            <option value="12 months">Last 12 Months</option>
          </select>
        </td>
      </tr>
-->
    </table>

    <p>
      ${h.submit('submit', 'Submit Query')}
    </p>

    ${h.end_form()}

    <p>
      Patch Name searches support * to match any.<br/ >
      Example: linux-2.4.*-ac
    </p>
