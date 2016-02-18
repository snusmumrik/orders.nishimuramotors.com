json.array!(@accounts) do |account|
  json.extract! account, :id, :supplier_id, :identifier, :password
  json.url account_url(account, format: :json)
end
