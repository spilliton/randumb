Gem::Specification.new do |s|
  s.name        = "randumb"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Kloepping"]
  s.homepage    = "https://github.com/spilliton/randumb"
  s.summary     = "Adds the ability to pull random records from ActiveRecord"
  s.files       = ["lib/randumb.rb"]
 
  s.required_rubygems_version = ">= 1.6.6"
 
  s.add_development_dependency "rspec"
end
