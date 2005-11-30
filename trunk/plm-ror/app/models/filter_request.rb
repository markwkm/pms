class FilterRequest < ActiveRecord::Base
  belongs_to :filter
  belongs_to :filter_request_state
  belongs_to :patch
  belongs_to :software
end
