# -*- coding: utf-8 -*-
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>${config['brand.short_name']} : ${self.title()}</title>
    <link href="/stylesheets/scaffold.css" media="screen" rel="Stylesheet"
     type="text/css" />
    <script src="/javascripts/prototype-1.6.0.3.js" type="text/javascript" />
    </script>
  </head>
  <body>
    <div class="top">
      <h1><a href="/">${config['brand.name']}</a></h1>
    </div>

    <div id="menu">
      <ul>
        <li class="sub"><div class="title">Menu</div></li>
        <ul class="sub">
          <li class="sub">
            <a href="howto.html">${config['brand.short_name']} How-to</a>
          </li>
          <li class="sub">
            <a href="/developer/show">User Page</a>
          </li>
          <li class="sub">
            <a href="/patch/search">Search</a>
          </li>
          <li class="sub">
            <a href="/patch/new">Add Patch</a>
          </li>
          <li class="sub">
% if 'user' in session:
            <a href="/account/logout">Logout</a>
% else:
            <a href="/account/login">Login</a>
          </li>
          <li class="sub">
            <a href="/account/signup">Sign Up</a>
% endif
          </li>
        </ul>
      </ul>
    </div>
    ${self.body()}
  </body>
</html>
