json.array!(@suppliers) do |supplier|
  json.extract! supplier, :id, :spree_product_id, :ngsj, :iiparts, :amazon, :rakuten, :yahoo
  json.url supplier_url(supplier, format: :json)
end
