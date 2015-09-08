require 'test_helper'

class ProfitsControllerTest < ActionController::TestCase
  setup do
    @profit = profits(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:profits)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create profit" do
    assert_difference('Profit.count') do
      post :create, profit: { percentage: @profit.percentage }
    end

    assert_redirected_to profit_path(assigns(:profit))
  end

  test "should show profit" do
    get :show, id: @profit
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @profit
    assert_response :success
  end

  test "should update profit" do
    patch :update, id: @profit, profit: { percentage: @profit.percentage }
    assert_redirected_to profit_path(assigns(:profit))
  end

  test "should destroy profit" do
    assert_difference('Profit.count', -1) do
      delete :destroy, id: @profit
    end

    assert_redirected_to profits_path
  end
end
