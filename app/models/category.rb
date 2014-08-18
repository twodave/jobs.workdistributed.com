class Category
  include Mongoid::Document
  field :name, type: String

  has_many :listings, :class_name => "Listing", inverse_of: :category
  def listing_count
    listings.active.count
  end
  def max_listing_paid_utc
    listings.active.max(:paid_utc)
  end
end