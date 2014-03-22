$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'
require 'faker'
require 'active_record'
require 'active_support/dependencies'
require 'randumb'

MODELS_PATH = File.join(File.dirname(__FILE__), 'models')

config = YAML::load(File.open(File.expand_path("../databases.yml", __FILE__)))
version = ActiveRecord::VERSION::STRING
driver = (ENV["DB"] or "sqlite3").downcase
in_memory = config[driver]["database"] == ":memory:"
    
# http://about.travis-ci.org/docs/user/database-setup/
commands = {
  "mysql"    => "mysql -e 'create database randumb_test;'",
  "postgres" => "psql -c 'create database randumb_test;' -U postgres"
}
%x{#{commands[driver] || true}}
    
ActiveRecord::Base.establish_connection config[driver]
puts "Using #{RUBY_VERSION} AR #{version} with #{driver}"


ActiveRecord::Base.connection.create_table(:artists, :force => true) do |t|
  t.string   "name"
  t.integer  "views"
  t.float    "rating"
  t.datetime "created_at"
  t.datetime "updated_at"
end
  
ActiveRecord::Base.connection.create_table(:albums, :force => true) do |t|
  t.string  "name"
  t.integer "views"
  t.integer "artist_id"
  t.datetime "created_at"
  t.datetime "updated_at"
end
  
# setup models for lazy load
dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
dep.autoload_paths.unshift MODELS_PATH

# load factories now
require 'test/models/factories'

# clear db for every test
class Test::Unit::TestCase

  def setup
    Artist.delete_all
    Album.delete_all
  end

end


# Silence deprications
ActiveSupport::Deprecation.silenced = true
