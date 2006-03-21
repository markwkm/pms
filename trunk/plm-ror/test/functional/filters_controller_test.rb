require File.dirname(__FILE__) + '/../test_helper'
require 'filters_controller'

# Re-raise errors caught by the controller.
class FiltersController; def rescue_action(e) raise e end; end

class FiltersControllerTest < Test::Unit::TestCase
  fixtures :softwares, :sources, :users, :filter_types, :filters

  def setup
    @controller = FiltersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @user = users(:robot)
    @software = softwares(:linux)
    @filter_type = filter_types(:first_filter_type)
  end

  def test_create_logged_in
    num_filters = Filter.count
    file = uploaded_file("#{File.expand_path(RAILS_ROOT)}/test/hi")

    login_authenticate(@user['login'], 'robot')
    post :create, :filter => { :name => 'a new filter',
        :software_id => @software['id'], :runtime => 1,
        :filename => 'new_filter.sh', :filter_type_id => @filter_type['id'],
        :file => file }

    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_filters + 1, Filter.count
    #
    # This should get the most recently inserted filter.
    #
    filter = Filter.find(:first, :order => 'id DESC')
    #
    # Test to make sure we are encoding/decoding the filters properly.
    #
    assert_equal 'hello', Base64.decode64(filter['file']).strip
  end

  def test_create_not_logged_in
    post :create, :filter => {}

    assert_response :redirect
    assert_redirected_to :controller => 'login'
  end

  def test_destroy_not_logged_in
    post :destroy, :id => 1

    assert_response :redirect
    assert_redirected_to :controller => 'login'
  end

  def test_edit_not_logged_in
    get :edit, :id => 1

    assert_response :redirect
    assert_redirected_to :controller => 'login'
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:filters)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:filter)
    assert assigns(:filter).valid?
  end

  def test_new_not_logged_in
    get :new

    assert_response :redirect
    assert_redirected_to :controller => 'login'
  end

  def test_update_not_logged_in
    post :update, :id => 1

    assert_response :redirect
    assert_redirected_to :controller => 'login'
  end
end
