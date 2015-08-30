class Spree::Order < ActiveRecord::Base
  belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address'
  alias_attribute :billing_address, :bill_address

  belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address'
  alias_attribute :shipping_address, :ship_address

  belongs_to :store, class_name: 'Spree::Store'
  has_many :state_changes, as: :stateful, dependent: :destroy
  has_many :line_items, -> { order("#{Spree::LineItem.table_name}.created_at ASC") }, dependent: :destroy, inverse_of: :order
  has_many :payments, dependent: :destroy
  has_many :return_authorizations, dependent: :destroy, inverse_of: :order
  has_many :reimbursements, inverse_of: :order
  has_many :adjustments, -> { order("#{Adjustment.table_name}.created_at ASC") }, as: :adjustable, dependent: :destroy
  has_many :line_item_adjustments, through: :line_items, source: :adjustments
  has_many :shipment_adjustments, through: :shipments, source: :adjustments
  has_many :inventory_units, inverse_of: :order
  has_many :products, through: :variants
  has_many :variants, through: :line_items
  has_many :refunds, through: :payments
  has_many :all_adjustments,
  class_name: 'Spree::Adjustment',
  foreign_key: :order_id,
  dependent: :destroy,
  inverse_of: :order

  has_many :order_promotions, class_name: 'Spree::OrderPromotion'
  has_many :promotions, through: :order_promotions, class_name: 'Spree::Promotion'

  has_many :shipments, dependent: :destroy, inverse_of: :order do
    def states
      pluck(:state).uniq
    end
  end

  paginates_per 10
end
