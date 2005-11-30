class Filter < ActiveRecord::Base
  belongs_to :software

  has_many :filter_requests
end
