#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

require 'bz2'

class FilterRequestsController < ApplicationController
  def output
    @filter_request = FilterRequest.find(params[:id])
    @output = BZ2::Reader.new(Base64.decode64(@filter_request[:output])).read
  end
end
