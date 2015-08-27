require 'test_helper'

class Spree::AddressesControllerTest < ActionController::TestCase
  setup do
    @spree_address = spree_addresses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spree_addresses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spree_address" do
    assert_difference('Spree::Address.count') do
      post :create, spree_address: {  }
    end

    assert_redirected_to spree_address_path(assigns(:spree_address))
  end

  test "should show spree_address" do
    get :show, id: @spree_address
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spree_address
    assert_response :success
  end

  test "should update spree_address" do
    patch :update, id: @spree_address, spree_address: {  }
    assert_redirected_to spree_address_path(assigns(:spree_address))
  end

  test "should destroy spree_address" do
    assert_difference('Spree::Address.count', -1) do
      delete :destroy, id: @spree_address
    end

    assert_redirected_to spree_addresses_path
  end
end
