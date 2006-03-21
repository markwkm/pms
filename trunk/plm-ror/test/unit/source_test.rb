require File.dirname(__FILE__) + '/../test_helper'

class SourceTest < Test::Unit::TestCase
  fixtures :softwares, :sources

  def setup
    @source = sources(:kernel_org)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Source, @source
  end
end
