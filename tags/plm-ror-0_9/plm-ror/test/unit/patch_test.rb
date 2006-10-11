require File.dirname(__FILE__) + '/../test_helper'

class PatchTest < Test::Unit::TestCase
  fixtures :softwares, :sources, :users, :filter_types, :filters,
      :filter_request_states, :patches

  def setup
    @patch = patches(:linux_2_5_0)
    @patch_1 = patches(:patch_level_one)
    @patch_2 = patches(:patch_level_two)
    @patch_3 = patches(:patch_level_three)
  end

  def test_applies_tree_all
    #
    # A baseline patch should return an empty array.
    #
    tree = @patch.applies_tree
    assert_equal 0, tree.length
    #
    # Test a patch that applies to something
    #
    tree = @patch_3.applies_tree
    assert_equal 3, tree.length
  end

  def test_applies_tree_with_limit
    #
    # A patch that applies to a baseline patch should only return 1 item when
    # asked for only 1 patch name to be returned.
    #
    tree = @patch_1.applies_tree(1)
    assert_equal 1, tree.length
    #
    # A patch that applies to a patch that applies to more patches should
    # return the 1 item and an ellipsis when we ask for only 1 patch name to
    # be returned.
    #
    tree = @patch_2.applies_tree(1)
    assert_equal 2, tree.length
    assert_equal '...', tree[tree.length - 1]
    #
    # A patch that applies to a patch that applies to more patches should
    # return all the patch names when we limit it to more than what is asked
    # for.
    #
    tree = @patch_1.applies_tree(3)
    assert_equal 1, tree.length
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
