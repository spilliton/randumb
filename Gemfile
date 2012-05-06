source "http://rubygems.org"

gem 'activesupport', '3.0.0'
gem 'activerecord', '3.0.0'
gem 'rake'

group :test do
  db_env = ENV['DB'] || 'sqlite3'
  case db_env 
  when 'sqlite3'
    gem 'sqlite3', '1.3.5' 
  when 'mysql'
    gem 'mysql2', '~> 0.2.0'
  when 'postgres'
    gem 'pg'
  end

  gem 'shoulda'
  gem 'factory_girl', "~> 3.0"
  gem 'faker'
end