require File.dirname(__FILE__) + '/../test_helper'

class SoftwareTest < Test::Unit::TestCase
  fixtures :softwares

  def setup
    @software = Software.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Software,  @software
  end
end
