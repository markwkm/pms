require File.dirname(__FILE__) + '/../test_helper'

class FilterRequestTest < Test::Unit::TestCase
  fixtures :filter_requests

  def setup
    @filter_request = FilterRequest.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FilterRequest,  @filter_request
  end
end
