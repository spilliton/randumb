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
      
        # store these for including on final scope
        original_includes = relation.includes_values
        original_selects = relation.select_values
        
        # clear these for our id only query
        relation.select_values = []
        relation.includes_values = []
      
        # do original query but only for id field
        id_only_relation = relation.select("#{table_name}.id")
        id_results = connection.select_all(id_only_relation.to_sql)
      
        # get requested number of random ids
        ids = id_results.shuffle[0,max_items].collect { |h| h['id'] }
  
        # build scope for final query
        the_scope = klass.includes(original_includes)

        # specifying empty selects caused bug in rails 3.0.0/3.0.1
        the_scope = the_scope.select(original_selects) unless original_selects.empty? 

        # get dem records
        records = the_scope.find_all_by_id(ids)
                
        # return only the first record if method was called without parameters
        if return_first_record
          records.first
        else
          records
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
