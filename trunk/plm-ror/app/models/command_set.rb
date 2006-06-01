#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class CommandSet < ActiveRecord::Base
  has_and_belongs_to_many :softwares
end

