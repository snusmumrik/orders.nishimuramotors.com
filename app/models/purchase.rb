class Purchase < ActiveRecord::Base
  belongs_to :spree_product
  belongs_to :spree_order
end
