require 'machinist/active_record'

Artist.blueprint do
  name { Faker::Lorem.words(3).join(' ') }
  views { rand(50) }
end

Album.blueprint do
  name { Faker::Lorem.words(3).join(' ') }
  views { rand(50) }
  artist { Artist.make! }
end