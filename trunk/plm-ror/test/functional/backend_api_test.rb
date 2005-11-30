require File.dirname(__FILE__) + '/../test_helper'
require 'backend_controller'

require 'base64'
require 'bz2'

class BackendController; def rescue_action(e) raise e end; end

class BackendControllerApiTest < Test::Unit::TestCase
  fixtures :users
  fixtures :softwares
  fixtures :sources
  fixtures :patches
  fixtures :filter_types
  fixtures :filters
  fixtures :filter_request_states
  fixtures :filter_requests

  def setup
    @controller = BackendController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

#  def test_add_patch
#    result = invoke :add_patch
#    assert_equal nil, result
#  end

  def test_submit_result
    filter_result = 'RESULT: PASS\n' +
        'RESULT-DETAIL: Compiles OK for UP & SMP with default options'
    bz2 = p = BZ2::Writer.new
    bz2.write('hi')
    output = Base64.encode64(bz2.flush)

    result = invoke :submit_result, 1, filter_result, output
    assert_response :success
  end
end
