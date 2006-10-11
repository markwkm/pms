#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class PatchDetail < ActionWebService::Struct
  member :diff, :base64
  member :path, :string
  member :remote_identifier, :string
  member :reverse, :boolean
  member :source_id, :int
  member :strip_level, :int
end
