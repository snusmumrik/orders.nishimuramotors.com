require 'test_helper'

class Spree::OrdersControllerTest < ActionController::TestCase
  setup do
    @spree_order = spree_orders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spree_orders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spree_order" do
    assert_difference('Spree::Order.count') do
      post :create, spree_order: {  }
    end

    assert_redirected_to spree_order_path(assigns(:spree_order))
  end

  test "should show spree_order" do
    get :show, id: @spree_order
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spree_order
    assert_response :success
  end

  test "should update spree_order" do
    patch :update, id: @spree_order, spree_order: {  }
    assert_redirected_to spree_order_path(assigns(:spree_order))
  end

  test "should destroy spree_order" do
    assert_difference('Spree::Order.count', -1) do
      delete :destroy, id: @spree_order
    end

    assert_redirected_to spree_orders_path
  end
end
