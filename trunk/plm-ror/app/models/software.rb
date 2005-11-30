class Software < ActiveRecord::Base
  has_many :patch_acls
  has_many :patches
  has_many :filters
end
