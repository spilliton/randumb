class Artist < ActiveRecord::Base
  has_many :albums
  
  scope :at_least_three_views, -> { where("views >= 3") }
end