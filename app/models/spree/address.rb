class Spree::Address < ActiveRecord::Base
  belongs_to :country, class_name: "Spree::Country"
  belongs_to :state, class_name: "Spree::State"

  has_many :shipments, inverse_of: :address
end
