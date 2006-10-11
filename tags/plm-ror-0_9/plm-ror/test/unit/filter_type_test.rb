require File.dirname(__FILE__) + '/../test_helper'

class FilterTypeTest < Test::Unit::TestCase
  fixtures :filter_types

  def setup
    @filter_type = FilterType.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FilterType,  @filter_type
  end
end
