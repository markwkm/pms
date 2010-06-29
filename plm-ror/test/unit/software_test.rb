require File.dirname(__FILE__) + '/../test_helper'

class SoftwareTest < Test::Unit::TestCase
  fixtures :softwares, :sources

  def setup
    @software = softwares(:linux)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Software, @software
  end
end
