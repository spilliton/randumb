Gem::Specification.new do |s|
  s.name        = "randumb"
  s.version     = "0.2.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Kloepping"]
  s.homepage    = "https://github.com/spilliton/randumb"
  s.summary     = "Adds the ability to pull random records from ActiveRecord"
  s.files       = ["lib/randumb.rb"]
 
  s.add_dependency 'activesupport', '>= 3.0.0'
  s.add_dependency 'activerecord', '>= 3.0.0'
  s.add_dependency 'rake'

  # for gem dev
  db_env = ENV['DB'] || 'sqlite3'
  case db_env 
  when 'sqlite3'
    s.add_development_dependency 'sqlite3', '1.3.5' 
  when 'mysql'
    s.add_development_dependency 'mysql2', '~> 0.2.0'
  when 'postgres'
    s.add_development_dependency 'pg'
  end

  s.add_development_dependency "shoulda"
  s.add_development_dependency "factory_girl", "~> 3.0"
  s.add_development_dependency "faker"
end
