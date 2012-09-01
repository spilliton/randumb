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
        return random_by_id_shuffle(max_items) if is_randumb_postges_case?(relation, ranking_column)
        raise_unless_valid_ranking_column(ranking_column)

        order_clause = random_order_clause(ranking_column)
        the_scope = relation.order(order_clause)

        # override the limit if they are requesting multiple records
        if max_items && (!relation.limit_value || relation.limit_value > max_items)
          the_scope = the_scope.limit(max_items)
        end

        # return first record if method was called without parameters
        max_items ? the_scope.all : the_scope.first
      end


      # This was my first implementation, adding it as an option for people to use
      # and to fall back on for pesky DB one off situations...
      #    https://github.com/spilliton/randumb/issues/7
      def random_by_id_shuffle(max_items = nil)
        return_first_record = max_items.nil? # see return switch at end
        max_items ||= 1
        relation = clone
        ids = fetch_random_ids(relation, max_items)
  
        # build new scope for final query
        the_scope = klass.includes(includes_values)

        # specifying empty selects caused bug in rails 3.0.0/3.0.1
        the_scope = the_scope.select(select_values) unless select_values.empty? 

        # get the records and shuffle since the order of the ids
        # passed to find_all_by_id isn't retained in the result set
        records = the_scope.find_all_by_id(ids).shuffle!
                
        # return first record if method was called without parameters
        return_first_record ? records.first : records
      end

      private

      # postgres won't let you do an order_by when also doing a distinct
      # let's just use the in-memory option in this case
      def is_randumb_postges_case?(relation, ranking_column)
        if relation.respond_to?(:uniq_value) && relation.uniq_value && connection.adapter_name =~ /postgres/i
          if ranking_column 
            raise Exception, "random_weighted: not possible when using .uniq and the postgres db adapter"
          else
            return true
          end
        end
      end

      # columns used for ranking must be a numeric type b/c they are multiplied
      def raise_unless_valid_ranking_column(ranking_column)
        if ranking_column
          column_data = @klass.columns_hash[ranking_column.to_s]
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a column on #{@klass.table_name}!") unless column_data
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a numeric column on #{@klass.table_name}!") unless [:integer, :float].include?(column_data.type)
        end
      end

      # sligtly different for each DB
      def random_syntax
        if connection.adapter_name =~ /(sqlite|postgres)/i
          "RANDOM()"
        elsif connection.adapter_name =~ /mysql/i
          "RAND()"
        else
          raise Exception, "ActiveRecord adapter: '#{connection.adapter_name}' not supported by randumb.  Send a pull request or open a ticket: https://github.com/spilliton/randumb"
        end
      end

      # builds the order clause to be appended in where clause
      def random_order_clause(ranking_column)
        if ranking_column.nil?
          random_syntax
        else
          if connection.adapter_name =~ /sqlite/i
            # computer multiplication is faster than division I was once taught...so translate here
            max_int = 9223372036854775807.0
            multiplier = 1.0 / max_int 
            "(#{ranking_column} * ABS(#{random_syntax} * #{multiplier}) ) DESC"
          else
            "(#{ranking_column} * #{random_syntax}) DESC"
          end
        end
      end

      # Returns all matching ids from the db, shuffles them,
      # then returns an array containing at most max_ids
      def fetch_random_ids(relation, max_ids)
        # clear these for our id only query
        relation.select_values = []
        relation.includes_values = []
      
        # do original query but only for id field
        id_only_relation = relation.select("#{table_name}.id")
        id_results = connection.select_all(id_only_relation.to_sql)
      
        if max_ids == 1 && id_results.length > 0
          ids = [ id_results[ rand(id_results.length) ]['id'] ]
        else
          ids = id_results.shuffle![0,max_ids].collect!{ |h| h['id'] }
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