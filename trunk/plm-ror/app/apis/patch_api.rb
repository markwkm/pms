#
# If you change any of the api_method parameters, the Web server needs to be
# bounced, even in test mode.
#
class PatchApi < ActionWebService::API::Base
  api_method :add_patch,
      :expects => [:string, :string, :string, :string, :string, :base64],
      :returns => [:int]
  api_method :command_set_get_content,
      :expects => [:string, :int, :string],
      :returns => [[Command]]
  api_method :get_applies_tree,
      :expects => [:int],
      :returns => [[:int]]
  api_method :get_patch,
      :expects => [:int],
      :returns => [[:string]]
  api_method :get_request,
      :expects => [:string],
      :returns => [[:string]]
  api_method :patch_add,
      :expects => [{ :user => :string }, { :password => :string },
          { :name => :string }, { :path => :string },
          { :remote_identifier => :string }, { :source_id => :int },
          { :applies_id => :int }, { :content => :base64 },
          { :file_type => :string}],
      :returns => [:int]
  api_method :patch_find_by_name,
      :expects => [:string],
      :returns => [:int]
  api_method :patch_get_list,
      :expects => [:string, [:int]],
      :returns => [[:string]]
  api_method :patch_get_value,
      :expects => [:int, :string],
      :returns => [:string]
  api_method :set_filter_request_state,
      :expects => [:int, :int],
      :returns => [:int]
  api_method :software_verify,
      :expects => [:string],
      :returns => [:int]
  api_method :source_get,
      :expects => [:int],
      :returns => [Source]
  api_method :source_get_by_software,
      :expects => [:int],
      :returns => [[Source]]
  api_method :submit_result,
      :expects => [:int, :string, :base64]
  api_method :source_sync_by_source,
      :expects => [{ :source_id => :int }],
      :returns => [[SourceSync]]
  api_method :user_verify,
      :expects => [:string, :string],
      :returns => [:int]
end
