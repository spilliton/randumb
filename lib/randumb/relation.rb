require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation

      # If the max_items argument is omitted, one random entity will be returned.
      # If you provide the integer argument, you will get back an array of records.
      def random(max_items = nil)
        random_weighted(nil, max_items)
      end

      # If ranking_column is provided, that named column wil be multiplied
      # by a random number to determine probability of order. The ranking column must be numeric.
      def random_weighted(ranking_column, max_items = nil)
        relation = clone

        # postgres won't let you do an order_by when also doing a distinct
        # let's just use the in-memory option in this case
        if relation.respond_to?(:uniq_value) && relation.uniq_value && connection.adapter_name =~ /postgres/i
          if ranking_column 
            raise Exception, "random_weighted: not possible when using .uniq and the postgres db adapter"
          else
            return random_by_id_shuffle(max_items)
          end
        end

        # ensure a valid column for ranking
        if ranking_column
          column_data = @klass.columns_hash[ranking_column.to_s]
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a column on #{@klass.table_name}!") unless column_data
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a numeric column on #{@klass.table_name}!") unless [:integer, :float].include?(column_data.type)
        end

        # choose the right syntax
        if connection.adapter_name =~ /(sqlite|postgres)/i
          rand_syntax = "RANDOM()"
        elsif connection.adapter_name =~ /mysql/i
          rand_syntax = "RAND()"
        else
          raise Exception, "ActiveRecord adapter: '#{connection.adapter_name}' not supported by randumb.  Send a pull request or open a ticket: https://github.com/spilliton/randumb"
        end

        order_clause =  if ranking_column.nil?
                          rand_syntax
                        else
                          if connection.adapter_name =~ /sqlite/i
                            # computer multiplication is faster than division I was once taught...so translate here
                            max_int = 9223372036854775807.0
                            multiplier = 1.0 / max_int 
                            "(#{ranking_column} * ABS(#{rand_syntax} * #{multiplier}) ) DESC"
                          else
                            "(#{ranking_column} * #{rand_syntax}) DESC"
                          end
                        end

        the_scope = relation.order(order_clause)

        # override the limit if they are requesting multiple records
        if max_items && (!relation.limit_value || relation.limit_value > max_items)
          the_scope = the_scope.limit(max_items)
        end

        # return first record if method was called without parameters
        if max_items.nil?
          the_scope.first
        else
          the_scope.all
        end
      end


      # This was my first implementation, adding it as an option for people to use
      # and to fall back on for pesky DB one off situations...
      #  https://github.com/spilliton/randumb/issues/7
      def random_by_id_shuffle(max_items = nil)
        return_first_record = max_items.nil?# see return switch at end
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
        if max_items == 1 && id_results.length > 0
          ids = [ id_results[ rand(id_results.length) ]['id'] ]
        else
          ids = id_results.shuffle![0,max_items].collect!{ |h| h['id'] }
        end
  
        # build scope for final query
        the_scope = klass.includes(original_includes)

        # specifying empty selects caused bug in rails 3.0.0/3.0.1
        the_scope = the_scope.select(original_selects) unless original_selects.empty? 

        # get the records and shuffle since the order of the ids
        # passed to find_all_by_id isn't retained in the result set
        records = the_scope.find_all_by_id(ids).shuffle!
                
        # return first record if method was called without parameters
        if return_first_record
          records.first
        else
          records
        end
      end

    end 

    
    # Class methods
    module Base
      def random(max_items = nil)
        relation.random(max_items)
      end

      def random_weighted(ranking_column, max_items = nil)
        relation.random_weighted(ranking_column, max_items)
      end

      def random_by_id_shuffle(max_items = nil)
        relation.random_by_id_shuffle(max_items)
      end
    end 


    # These get registered as class and instance methods
    module MethodMissingMagicks
      def method_missing(symbol, *args)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          random_weighted($1, *args)
        else
          super
        end
      end

      def respond_to?(symbol, include_private=false)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          true
        else
          super
        end
      end
    end

  end # ActiveRecord
end # Randumb