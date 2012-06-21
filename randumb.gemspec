# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "randumb/version"

Gem::Specification.new do |s|
  s.name        = "randumb"
  s.version     = Randumb::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Kloepping"]
  s.homepage    = "https://github.com/spilliton/randumb"
  s.summary     = "Adds the ability to pull random records from ActiveRecord"
  s.files       = Dir['lib/**/*.rb']
  s.test_files  = Dir['test/**/*.rb']

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
