# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">Search Results</%def>
    <h1>Search Results</h1>

    <table border="1">
      <tr>
        <th>Patch Name</th>
        <th>Applies Tree</th>
        <th>Created Date</th>
      </tr>
% for patch in c.patches:
      <tr>
        <td valign="top">
          <a href="/patch/show/${patch.id}">${patch.name}</a>
        </td>
        <td valign="top">
  % if patch.patch_id is None:
          [ none - baseline ]
  % else:
          <a href="/patch/show/${patch.patch_id}">${patch.patch.name}</a>
  % endif
        </td>
        <td valign="top">${patch.created_on}</td>
      </tr>
% endfor
    </table>

    <p align="center">
      ${c.patches.pager()}
    </p>
