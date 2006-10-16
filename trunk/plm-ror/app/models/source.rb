#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class Source < ActiveRecord::Base
  belongs_to :software
  belongs_to :source_sync
end
