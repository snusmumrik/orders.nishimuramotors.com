json.array!(@profits) do |profit|
  json.extract! profit, :id, :percentage
  json.url profit_url(profit, format: :json)
end
