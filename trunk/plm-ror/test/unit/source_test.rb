require File.dirname(__FILE__) + '/../test_helper'

class SourceTest < Test::Unit::TestCase
  fixtures :sources

  def setup
    @source = Source.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Source,  @source
  end
end
