require 'test_helper'

class MainControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get connect" do
    get :connect
    assert_response :success
  end

  test "should get select" do
    get :select
    assert_response :success
  end

  test "should get submit" do
    get :submit
    assert_response :success
  end

end
