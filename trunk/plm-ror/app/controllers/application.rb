#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  model :user

  def authenticate
    unless @session["user"]
      @session["return_to"] = @request.request_uri
      redirect_to :controller => "login"
      return false
    end
  end
end
