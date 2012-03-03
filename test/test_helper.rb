$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'faker'
require 'active_record'
require 'active_record/fixtures'
require 'randumb'

FIXTURES_PATH = File.join(File.dirname(__FILE__), 'fixtures')

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
dep.autoload_paths.unshift FIXTURES_PATH

ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false
  load File.join(FIXTURES_PATH, 'schema.rb')
end

#Fixtures.create_fixtures(FIXTURES_PATH, ActiveRecord::Base.connection.tables)

require File.expand_path(File.dirname(__FILE__) + "/blueprints")

# class ActiveSupport::TestCase
  
#   # For machinist
#   Machinist.configure do |config|
#     config.cache_objects = false
#   end
  
#   setup { Machinist.reset_before_test }
  
# end
