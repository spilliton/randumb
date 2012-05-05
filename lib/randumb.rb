require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation
      
      def random(max_items = nil)
        return_first_record = max_items.nil? # see return switch at end
        max_items ||= 1
        relation = clone
      
        case connection.adapter_name
        when "SQLite", "PostgreSQL"
          rand_syntax = "RANDOM()"
        when "MySQL"
          rand_syntax = "RAND()"
        else
          throw new Exception("ActiveRecord adapter: '#{connection.adapter_name}' not supported by randumb.  Send a pull request or open a ticket: https://github.com/spilliton/randumb")
        end

        the_scope = relation.order(rand_syntax)
        the_scope = the_scope.limit(max_items) unless relation.limit_value && relation.limit_value < max_items
                
        # return first record if method was called without parameters
        if return_first_record
          the_scope.first
        else
          the_scope.all
        end
      end

    end # Relation
    
    module Base
      # Class method
      def random(max_items = nil)
        relation.random(max_items)
      end
    end 
    
    
  end # ActiveRecord
end # Randumb

# Mix it in
class ActiveRecord::Relation
  include Randumb::ActiveRecord::Relation
end

class ActiveRecord::Base
  extend Randumb::ActiveRecord::Base
end
