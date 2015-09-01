class Spree::Product < ActiveRecord::Base
  has_many :product_option_types, dependent: :destroy, inverse_of: :product
  has_many :option_types, through: :product_option_types
  has_many :product_properties, dependent: :destroy, inverse_of: :product
  has_many :properties, through: :product_properties

  has_many :classifications, dependent: :delete_all, inverse_of: :product
  has_many :taxons, through: :classifications

  has_many :product_promotion_rules, class_name: 'Spree::ProductPromotionRule'
  has_many :promotion_rules, through: :product_promotion_rules, class_name: 'Spree::PromotionRule'

  belongs_to :tax_category, class_name: 'Spree::TaxCategory'
  belongs_to :shipping_category, class_name: 'Spree::ShippingCategory', inverse_of: :products

  has_one :master,
  -> { where is_master: true },
  inverse_of: :product,
  class_name: 'Spree::Variant'

  has_many :variants,
  -> { where(is_master: false).order("#{::Spree::Variant.quoted_table_name}.position ASC") },
  inverse_of: :product,
  class_name: 'Spree::Variant'

  has_many :variants_including_master,
  -> { order("#{::Spree::Variant.quoted_table_name}.position ASC") },
  inverse_of: :product,
  class_name: 'Spree::Variant',
  dependent: :destroy

  has_many :prices, -> { order('spree_variants.position, spree_variants.id, currency') }, through: :variants

  has_many :stock_items, through: :variants_including_master

  has_many :line_items, through: :variants_including_master
  has_many :orders, through: :line_items

  has_one :supplier, foreign_key: :spree_product_id
  has_one :price, foreign_key: :spree_product_id

  paginates_per 10
end
