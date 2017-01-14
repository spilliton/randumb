class Artist < ActiveRecord::Base
  has_many :albums

  if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new("3.2")
    default_scope { where("artists.deleted_at IS NULL") }
  else
    default_scope where("artists.deleted_at IS NULL")
  end

  scope :at_least_three_views, -> { where("views >= 3") }
end
