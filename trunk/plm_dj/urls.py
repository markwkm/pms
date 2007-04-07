from django.conf.urls.defaults import *

urlpatterns = patterns('',
    # Example:
    # (r'^plm_dj/', include('plm_dj.foo.urls')),

    # Uncomment this for admin:
     (r'^admin/', include('django.contrib.admin.urls')),
)
