#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class RssController < ApplicationController
  session :off, :only => :feed

  def index
    @base_link = "#{request.protocol}#{request.host_with_port}"
    @patches = Patch.find(:all,
        :select => 'id, name, software_id, user_id, created_on',
        :order => 'id DESC',
        :limit => 10)
    render :layout => false
  end
end
