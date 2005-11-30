require File.dirname(__FILE__) + '/../test_helper'

class PatchTest < Test::Unit::TestCase
  fixtures :patches

  def setup
    @patch = Patch.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Patch,  @patch
  end
end
