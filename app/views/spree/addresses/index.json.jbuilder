json.array!(@spree_addresses) do |spree_address|
  json.extract! spree_address, :id
  json.url spree_address_url(spree_address, format: :json)
end
