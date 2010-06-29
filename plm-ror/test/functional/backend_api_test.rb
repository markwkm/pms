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

    @filter = filters(:hello_filter)
    @filter_request = filter_requests(:first_filter_request)
  end

  def test_get_filter
    filter = invoke :get_filter, @filter['id']
    assert_equal 'hello', Base64.decode64(filter).strip
  end

  def test_submit_result
    filter_output = 'hi'
    filter_result = 'RESULT: PASS\n' +
        'RESULT-DETAIL: Compiles OK for UP & SMP with default options'
    bz2 = p = BZ2::Writer.new
    bz2.write(filter_output)
    output = Base64.encode64(bz2.flush)

    num_filter_requests = FilterRequest.count
    filter_request = FilterRequest.find(@filter_request['id'])
    assert_nil filter_request['result']
    assert_nil filter_request['result_detail']
    assert_nil filter_request['output']

    result = invoke :submit_result, @filter_request['id'], filter_result, output
    assert_response :success
    assert_equal num_filter_requests, FilterRequest.count
    filter_request = FilterRequest.find(@filter_request['id'])
    assert_equal 'PASS', filter_request['result']
    assert_equal 'Compiles OK for UP & SMP with default options',
        filter_request['result_detail']
    assert_equal filter_output,
        BZ2::Reader.new(Base64.decode64(filter_request['output'])).read
  end
end
