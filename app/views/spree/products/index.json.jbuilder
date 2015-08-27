json.array!(@spree_products) do |spree_product|
  json.extract! spree_product, :id
  json.url spree_product_url(spree_product, format: :json)
end
