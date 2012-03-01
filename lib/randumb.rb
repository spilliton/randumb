require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  
    #  https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation
      
      def random(max_items = nil)
        # return only the first record if method was called without parameters
        return_first_record = max_items.nil?
        max_items ||= 1

        # take out limit from relation to use later
    
        relation = clone
      
        # store these for including at the end
        original_includes = relation.includes_values
        original_selects = relation.select_values
        
        # clear these for our id only query
        relation.select_values = []
        relation.includes_values = []
      
        # does their original query but only for id fields
        id_only_relation = relation.select("#{table_name}.id")
        id_results = connection.select_all(id_only_relation.to_sql)
      
        ids = id_results.shuffle[0,max_items].collect { |h| h['id'] }
  
        the_scope = klass.includes(original_includes)
        # specifying empty selects caused bug in rails 3.0.0/3.0.1
        the_scope = the_scope.select(original_selects) unless original_selects.empty? 
        records = the_scope.find_all_by_id(ids)
                
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
      
    end # Base
    
    
  end # ActiveRecord
  
end # Randumb


# Mix it in
class ActiveRecord::Relation
  include Randumb::ActiveRecord::Relation
end

class ActiveRecord::Base
  extend Randumb::ActiveRecord::Base
end
