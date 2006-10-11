require File.dirname(__FILE__) + '/../test_helper'

class FilterRequestStateTest < Test::Unit::TestCase
  fixtures :filter_request_states

  def setup
    @filter_request_state = FilterRequestState.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of FilterRequestState,  @filter_request_state
  end
end
