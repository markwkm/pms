require File.dirname(__FILE__) + '/../test_helper'

class SourceSyncTest < Test::Unit::TestCase
  fixtures :source_syncs

  def setup
    @source_sync = SourceSync.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of SourceSync,  @source_sync
  end
end
