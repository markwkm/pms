# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">Add Patch</%def>
    <h1>Add Patch</h1>

    ${h.form(h.url(controller='patch', action='create'), method='post', enctype='multipart/form-data')}
      <table>
        <tr>
          <td>Patch Name:</td>
          <td>${h.text('name')}</td>
        </tr>
        <tr>
          <td>File to Upload:</td>
          <td>${h.file('diff')}</td>
        </tr>
        <tr>
          <td>Software Repository:</td>
          <td>${h.select('software_id', 1, c.software)}</td>
        </tr>
        <tr>
          <td>Patch Strip Level:</td>
          <td>${h.text('strip_level', 1)}</td>
        </tr>
      </table>

      <p>
        The patch file can be in plaintext, gzip or bzip2 format.
        [autodetected]<br/>
      </p>

      <table>
        <tr>
          <td>Patch name to apply to:</td>
          <td>${h.text('applies_name')}</td>
          <td><div id="applies_name_div"></div></td>
        </tr>
        <tr>
          <td>Apply patch in reverse</td>
          <td>${h.checkbox('reverse')}</td>
        </tr>
      </table>

      <p>
        Note: Official baseline versions are in the system with placeholder
        patch ID's
      </p>

      <p>
        If you can't remember the name of a patch, you can
        <a href="/patch/search">search</a> for it.
      </p>

      <p>
        ${h.submit('submit', 'Add Patch')}
      </p>
    ${h.end_form()}
