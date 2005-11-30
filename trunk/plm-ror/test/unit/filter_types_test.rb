require File.dirname(__FILE__) + '/../test_helper'

class FilterTypesTest < Test::Unit::TestCase
  fixtures :filter_types

  def setup
    @filter_types = FilterTypes.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FilterTypes,  @filter_types
  end
end
