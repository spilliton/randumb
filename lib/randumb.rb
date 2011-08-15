module ActiveRecord

  module Randumb
  
    #  https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb

    
    def random
      # take out limit from relation to use later
    
      relation = clone
    
      max_items = 15
      max_items = relation.limit_value if relation.limit_value
      relation.limit_value = nil
      original_includes = relation.includes_values
    
      # Get raw sql string and replace * with id
      sql = relation.to_sql.sub("*", "id")
      puts "raw sql: #{sql}"
      id_results = ActiveRecord::Base.connection.select_all(sql)
    
      while( used_ids.length < max_items && used_ids.length < id_results.length )
        rand_num = rand( id_results.length )
        used_ids[rand_num] = id_results[rand_num]["id"]
      end


      includes(original_includes).find_all_by_id(used_ids)
    end
  
  
  
  end

end


ActiveRecord::Relation.class_eval do
  # = Active Record Relation
    include Randumb
end
