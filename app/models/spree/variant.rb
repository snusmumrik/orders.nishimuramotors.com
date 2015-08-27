class Spree::Variant < ActiveRecord::Base
  belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :variants
  belongs_to :tax_category, class_name: 'Spree::TaxCategory'

  # delegate_belongs_to :product, :name, :description, :slug, :available_on,
  # :shipping_category_id, :meta_description, :meta_keywords,
  # :shipping_category

  has_many :inventory_units, inverse_of: :variant
  has_many :line_items, inverse_of: :variant
  has_many :orders, through: :line_items

  has_many :stock_items, dependent: :destroy, inverse_of: :variant
  has_many :stock_locations, through: :stock_items
  has_many :stock_movements, through: :stock_items

  has_many :option_value_variants, class_name: 'Spree::OptionValueVariant'
  has_many :option_values, through: :option_value_variants, class_name: 'Spree::OptionValue'

  has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"

  has_many :prices,
  class_name: 'Spree::Price',
  dependent: :destroy,
  inverse_of: :variant
end
