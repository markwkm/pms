#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class Command < ActiveRecord::Base
  has_many :command_sets
end
