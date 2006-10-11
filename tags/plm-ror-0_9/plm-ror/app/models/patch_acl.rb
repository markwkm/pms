#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class PatchAcl < ActiveRecord::Base
  has_many :users
end
