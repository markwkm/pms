require File.dirname(__FILE__) + '/../test_helper'

class CommandTest < Test::Unit::TestCase
  fixtures :commands

  def setup
    @command = Command.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Command,  @command
  end
end
