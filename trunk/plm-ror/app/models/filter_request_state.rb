#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class FilterRequestState < ActiveRecord::Base
  has_many :filter_requests
end
