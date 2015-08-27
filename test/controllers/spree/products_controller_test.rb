require 'test_helper'

class Spree::ProductsControllerTest < ActionController::TestCase
  setup do
    @spree_product = spree_products(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:spree_products)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create spree_product" do
    assert_difference('Spree::Product.count') do
      post :create, spree_product: {  }
    end

    assert_redirected_to spree_product_path(assigns(:spree_product))
  end

  test "should show spree_product" do
    get :show, id: @spree_product
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @spree_product
    assert_response :success
  end

  test "should update spree_product" do
    patch :update, id: @spree_product, spree_product: {  }
    assert_redirected_to spree_product_path(assigns(:spree_product))
  end

  test "should destroy spree_product" do
    assert_difference('Spree::Product.count', -1) do
      delete :destroy, id: @spree_product
    end

    assert_redirected_to spree_products_path
  end
end
