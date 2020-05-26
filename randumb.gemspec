# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "randumb/version"

Gem::Specification.new do |s|
  s.name        = "randumb"
  s.license     = 'MIT'
  s.version     = Randumb::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Zachary Kloepping"]
  s.homepage    = "https://github.com/spilliton/randumb"
  s.summary     = "Adds the ability to pull random records from ActiveRecord"
  s.files       = Dir['lib/**/*.rb']
  s.test_files  = Dir['test/**/*.rb']

  s.add_dependency 'rake'

  # need to test different versions of active record
  ar_env = ENV['ACTIVE_RECORD_VERSION'] || '>= 3.0.20'
  ar_env = ">= 5.0.1" if ar_env == 'latest'
  s.add_dependency 'activesupport', ar_env
  s.add_dependency 'activerecord', ar_env

  # I don't know how to ruby anymore...just locking these to versions that work
  # because I'm having a hard time debugging on latest versions
  s.add_development_dependency 'sqlite3', '~> 1.3.6'
  s.add_development_dependency 'mysql2', '0.4.10'
  s.add_development_dependency 'pg', '0.19.0'

  s.add_development_dependency 'bigdecimal', '1.4.2'
  s.add_development_dependency "minitest"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "faker"
  s.add_development_dependency "pry"
end
