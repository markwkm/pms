#
# Copyright (C) 2006 Mark Wong & Open Source Development Lab, Inc.
#

class Patch < ActiveRecord::Base
  belongs_to :patch
  belongs_to :software
  belongs_to :source
  belongs_to :user

  has_many :filter_requests, :order => 'id'
  #
  # This was an attempt to sort the filter requests by the filter name.  It
  # wasn't quite successfull...
  #
  #has_many :filter_requests, :finder_sql => 'SELECT filter_requests.* FROM filter_requests fr, filters f WHERE patch_id = #{self.id} AND fr.filter_id = f.id ORDER BY UPPER(f.name)'

  validates_uniqueness_of :name
  validates_presence_of :diff, :name

  def applies_tree(limit=0)
    tree = Array.new
    patch = self
    count = 0
    #
    # We want to use patch['patch_id'] as opposed to patch.patch since the
    # latter will execute a query against the database.
    #
    while !patch['patch_id'].nil?
      patch = Patch.find(patch['patch_id'], :select => 'name, patch_id')
      tree << patch['name']
      break if patch['patch_id'].nil?
      count += 1
      if limit != 0 and count == limit
        #
        # Add an ellipsis to indicate there are more patches that are not
        # listed.
        #
        tree << '...' unless patch['patch_id'].nil?
        break
      end
    end
    tree
  end

  def check_acl
    patch_acl = PatchAcl.find(:all,
        :conditions => ['software_id = ?', self.software_id])
    for acl in patch_acl
      #
      # Skip the check_acl call if the user is priviledged.
      #
      u = User.find_by_sql(
          'SELECT u.id ' +
          'FROM users u, patch_acls_users pau, patch_acls pa ' +
          "WHERE u.id = #{self.user_id} " +
          '  AND u.id = pau.user_id ' +
          '  AND pa.id = pau.patch_acl_id ' +
          "  AND pa.id = #{acl['id']} " +
          "  AND pa.software_id = #{self.software['id']}")[0]
      return true unless u.nil?
      return false if self.name =~ /#{acl['regex']}/
    end
    true
  end

  def queue_filters
    filters = Filter.find(:all,
        :conditions => ['software_id = 0 OR software_id = ?', self.software_id])
    for filter in filters
      fr = FilterRequest.new
      fr['filter_id'] = filter['id']
      fr['patch_id'] = self.id
      fr['state'] = STATE_QUEUED
      return false unless fr.save
    end
    true
  end
end
