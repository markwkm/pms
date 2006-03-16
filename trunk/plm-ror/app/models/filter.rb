class Filter < ActiveRecord::Base
  has_many :filter_requests

  belongs_to :software
end
