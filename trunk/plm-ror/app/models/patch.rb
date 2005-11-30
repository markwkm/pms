class Patch < ActiveRecord::Base
  belongs_to :patch
  belongs_to :software
  belongs_to :source
  belongs_to :user

  has_many :filter_requests

  validates_uniqueness_of :name
  validates_presence_of :diff, :name

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
    for f in filters
      fr = FilterRequest.new
      fr['filter_id'] = f['id']
      fr['patch_id'] = self.id
      return false unless fr.save
    end
    true
  end
end
