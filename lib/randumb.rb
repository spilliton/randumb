require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  
    #  https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation
      
      def random(max_items = 1)
        # take out limit from relation to use later
    
        relation = clone
      
        original_includes = relation.includes_values
        original_selects = relation.select_values
        relation.select_values = []
        relation.includes_values = []
      
        id_only_relation = relation.select("#{table_name}.id")
    
        # does their original query but only for id fields
        id_results = connection.select_all(id_only_relation.to_sql)
      
        used_ids = {}
      
        while( used_ids.length < max_items && used_ids.length < id_results.length )
          rand_num = rand( id_results.length )
          used_ids[rand_num] = id_results[rand_num]["id"]
        end

        includes(original_includes).find_all_by_id(used_ids.values)
      end

    end # Relation
    
    module Base
      
      # Class method
      def random(max_items = 1)
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