require 'randumb/version'
require 'randumb/syntax'
require 'randumb/relation'

# Mix it in
class ActiveRecord::Relation
  include Randumb::ActiveRecord::Relation
  include Randumb::ActiveRecord::MethodMissingMagicks
end

class ActiveRecord::Base
  extend Randumb::ActiveRecord::Base
  extend Randumb::ActiveRecord::MethodMissingMagicks
end
