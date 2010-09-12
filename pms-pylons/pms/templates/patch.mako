# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()"></%def>
    <h1>Patch Info</h1>

    <table>
      <tr>
        <td align="right">Patch Name:</td>
        <td>${c.patch.name}</td>
      </tr>
      <tr>
        <td align="right">md5sum:</td>
        <td>${c.patch.md5sum}</td>
      </tr>
      <tr>
        <td align="right">Repository:</td>
        <td>${c.patch.software.name}</td>
      </tr>
    </table>

    <table>
      <tr>
        <td align="right">Created By:</td>
        <td>${c.patch.user.login}</td>
      </tr>
      <tr>
        <td align="right">Created On:</td>
        <td>${c.patch.created_on}</td>
      </tr>
    </table>

% if c.patch.patch_id is not None:
    <table>
      <tr>
        <td align="right" valign="top">Applies Tree:</td>
        <td>
        </td>
      </tr>
    </table>
% endif

% if c.patch.patch_id is not None:
    <p>
      To <b>download</b> a bzip2 compressed copy of this patch, click
      <a href="/patch/download/${c.patch.id}">here</a>.<br />
      To <b>view</b> this patch, click
      <a href="/patch/view/${c.patch.id}">view</a>
      once only. (May take a while for big patches.)<br />
      To <b>view</b> scripts for this patch, click build, install or
      validate.<br />
    </p>
% endif

% if c.patch.patch_id is not None:
    <p>
      To <b>delete</b> this patch from the system, click
     <a href="/patch/delete">here</a>.
    </p>
% endif

    <table border="1">
      <tr>
        <th>Filter Name</th>
        <th>Detailed Result</th>
        <th>Status</th>
      </tr>
% for filter_request in c.filter_requests:
      <tr>
        <td>${filter_request.filter.name}</td>
        <td>${filter_request.result_detail}</td>
        <td align="center" class="${filter_request.result}">
  % if filter_request.result is None:
          ${filter_request.state}
  % else:
          <a href="/filter_request/output/${filter_request.id}">${filter_request.result}</a>
  % endif
        </td>
      </tr>
% endfor
    </table>

    <p>
      Select a completed filter's Status to view the output of the run log.
    </p>
