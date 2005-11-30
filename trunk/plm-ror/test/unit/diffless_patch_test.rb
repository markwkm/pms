require File.dirname(__FILE__) + '/../test_helper'

class DifflessPatchTest < Test::Unit::TestCase
  fixtures :diffless_patches

  def setup
    @diffless_patch = DifflessPatch.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of DifflessPatch,  @diffless_patch
  end
end
