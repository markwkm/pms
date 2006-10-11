#
## Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class CommandSetDetail < ActionWebService::Struct
  member :command, :string
  member :command_type, :string
  member :expected_result, :string
end

