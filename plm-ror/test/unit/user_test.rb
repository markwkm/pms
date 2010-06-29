require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users, :patches

  def setup
    @user = users(:robot)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of User,  @user
  end
end
