require File.dirname(__FILE__) + '/../test_helper'

class PatchTest < Test::Unit::TestCase
  fixtures :softwares, :sources, :users, :filter_types, :filters,
      :filter_request_states, :patches

  def setup
    @patch = patches(:linux_2_5_0)
  end

  def test_queue_filters
    num_filter_requests = FilterRequest.count
    @patch.queue_filters
    #
    # We only have 1 filter in the filters fixture.
    #
    assert_equal num_filter_requests + 1, FilterRequest.count
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Patch, @patch
  end
end
