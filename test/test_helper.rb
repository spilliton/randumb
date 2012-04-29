$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'
require 'faker'
require 'active_record'
require 'active_support/dependencies'
require 'active_support/core_ext/logger'
# require 'active_record/fixtures'
require 'randumb'

MODELS_PATH = File.join(File.dirname(__FILE__), 'models')


# establish connection
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Base.connection.create_table(:artists, :force => true) do |t|
  t.string   "name"
  t.integer  "views"
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

