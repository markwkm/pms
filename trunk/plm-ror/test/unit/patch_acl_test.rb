require File.dirname(__FILE__) + '/../test_helper'

class PatchAclTest < Test::Unit::TestCase
  fixtures :patch_acls

  def setup
    @patch_acl = PatchAcl.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PatchAcl,  @patch_acl
  end
end
