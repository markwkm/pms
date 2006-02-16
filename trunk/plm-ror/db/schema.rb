# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define() do

  create_table "command_sets", :force => true do |t|
    t.column "name", :text, :null => false
    t.column "command_set_type", :text, :null => false
  end

  add_index "command_sets", ["name", "command_set_type"], :name => "command_sets_name_key", :unique => true

  create_table "command_sets_softwares", :id => false, :force => true do |t|
    t.column "software_id", :integer, :null => false
    t.column "command_set_id", :integer, :null => false
    t.column "min_patch_id", :integer, :default => 0, :null => false
    t.column "max_patch_id", :integer, :default => 9223372036854775807, :null => false
  end

  create_table "commands", :force => true do |t|
    t.column "command_set_id", :integer, :null => false
    t.column "command_order", :integer, :null => false
    t.column "command", :text, :null => false
    t.column "command_type", :text, :null => false
    t.column "expected_result", :text
  end

  create_table "filter_request_states", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "code", :text
    t.column "detail", :text
  end

  create_table "filter_requests", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "filter_id", :integer, :null => false
    t.column "patch_id", :integer, :null => false
    t.column "filter_request_state_id", :integer, :default => 1, :null => false
    t.column "priority", :integer, :default => 1, :null => false
    t.column "result", :text
    t.column "result_detail", :text
    t.column "output", :binary
    t.column "started", :datetime
    t.column "completed", :datetime
  end

  create_table "filter_types", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006, :null => false
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006, :null => false
    t.column "code", :text, :null => false
    t.column "software_id", :integer
  end

  create_table "filters", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "software_id", :integer, :null => false
    t.column "name", :text, :null => false
    t.column "command", :text
    t.column "location", :text
    t.column "runtime", :integer
    t.column "filter_type_id", :integer, :null => false
  end

  add_index "filters", ["name"], :name => "filters_name_key", :unique => true

  create_table "patches", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "software_id", :integer, :null => false
    t.column "md5sum", :string, :limit => 40
    t.column "patch_id", :integer
    t.column "name", :text, :null => false
    t.column "diff", :binary
    t.column "user_id", :integer, :null => false
    t.column "p", :integer, :null => false
    t.column "source_id", :integer
    t.column "reverse", :boolean, :default => false, :null => false
    t.column "remote_identifier", :text
    t.column "path", :text
  end

  add_index "patches", ["name"], :name => "patches_name_key", :unique => true

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data", :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "softwares", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "name", :text, :null => false
    t.column "description", :text
  end

  add_index "softwares", ["name"], :name => "softwares_name_key", :unique => true

  create_table "sources", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006, :null => false
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006, :null => false
    t.column "software_id", :integer, :null => false
    t.column "root_location", :text, :null => false
    t.column "source_type", :text, :null => false
  end

  create_table "users", :force => true do |t|
    t.column "created_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "updated_on", :datetime, :default => Tue Jan 31 10:21:18 PST 2006
    t.column "login", :text, :null => false
    t.column "first", :text
    t.column "last", :text
    t.column "email", :text
    t.column "password", :text
  end

  add_index "users", ["login"], :name => "users_login_key", :unique => true

end