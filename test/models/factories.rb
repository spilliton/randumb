FactoryGirl.define do
  factory :artist do
    name { Faker::Lorem.words(3).join(' ') }
    views  { Random.rand(50) }
    rating { Random.rand(100) / 100 }
  end

  factory :album do
    name { Faker::Lorem.words(3).join(' ') }
    views { Random.rand(50) }
  end

end