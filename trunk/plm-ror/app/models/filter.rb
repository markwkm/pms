#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class Filter < ActiveRecord::Base
  has_many :filter_requests

  belongs_to :software
end
