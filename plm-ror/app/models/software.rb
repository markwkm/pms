#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class Software < ActiveRecord::Base
  has_many :patch_acls
  has_many :patches
  has_many :filters
  has_and_belongs_to_many :command_sets
end
