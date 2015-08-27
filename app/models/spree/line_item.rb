class Spree::LineItem < ActiveRecord::Base
  belongs_to :order, class_name: "Spree::Order", inverse_of: :line_items, touch: true
  belongs_to :variant, class_name: "Spree::Variant", inverse_of: :line_items
  belongs_to :tax_category, class_name: "Spree::TaxCategory"

  has_one :product, through: :variant

  has_many :adjustments, as: :adjustable, dependent: :destroy
  has_many :inventory_units, inverse_of: :line_item
end
