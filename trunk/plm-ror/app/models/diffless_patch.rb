class DifflessPatch < ActiveRecord::Base
  belongs_to :software
  belongs_to :user
  has_many :filter_requests, :foreign_key => 'patch_id'
end
