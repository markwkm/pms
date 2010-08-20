# -*- coding: utf-8 -*-
<%inherit file="/base.mako" />
<%def name="title()">${c.patch.name}</%def>
    <pre>
${c.diff}
    </pre>
