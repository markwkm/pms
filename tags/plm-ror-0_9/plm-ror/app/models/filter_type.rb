#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class FilterType < ActiveRecord::Base
  has_many :filters
end
