class Listing
  include Mongoid::Document

  validates :title, :presence => {:message => 'Job title cannot be blank'}
  validates :description, :presence => {:message => 'Job description cannot be blank'}
  validates :how_to_apply, :presence => {:message => 'How to apply cannot be blank'}

  belongs_to :category, :class_name => "Category", inverse_of: :listings
  embeds_one :company

  field :title, type: String
  field :slug, type: String

  field :description, type: String
  field :how_to_apply, type: String

  field :is_premium, type: Boolean, default: -> { false }

  field :created_utc, type: DateTime, default: -> { Time.now.utc }

  field :payment_token, type: String
  field :price_paid, type: Float
  field :paid_utc, type: DateTime, default: -> {nil}

  scope :active, where({:paid_utc.gte => 30.days.ago})

  def get_url
    if (ENV["RAILS_ENV"].eql?("production"))
      'https://jobs.workdistributed.com/' + slug
    else
      'http://localhost:3000/' + slug
    end
  end
end

class Company
  include Mongoid::Document

  validates :name, :presence => {:message => 'Company name cannot be blank'}
  validates :location, :presence => {:message => 'Company location cannot be blank'}
  validates :email, :presence => {:message => 'Email cannot be blank'}


  embedded_in :listing

  field :name, type: String
  field :location, type: String
  field :url, type: String
  field :email, type: String
  field :logo, type: ::BSON::Binary
end