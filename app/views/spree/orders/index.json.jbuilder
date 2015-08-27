json.array!(@spree_orders) do |spree_order|
  json.extract! spree_order, :id
  json.url spree_order_url(spree_order, format: :json)
end
