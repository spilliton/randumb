class Artist < ActiveRecord::Base
  has_many :albums
  
end