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

        # ensure a valid column
        if ranking_column
          column_data = @klass.columns_hash[ranking_column.to_s]
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a column on #{@klass.table_name}!") unless column_data
          raise ArgumentError.new("random_weighted: #{ranking_column} is not a numeric column on #{@klass.table_name}!") unless [:integer, :float].include?(column_data.type)
        end

        relation = clone
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
                            max_int = 9223372036854775807.0
                            "(#{ranking_column} * (ABS(#{rand_syntax})/#{max_int}) ) DESC"
                          else
                            "(#{ranking_column} * #{rand_syntax}) DESC"
                          end
                        end
        
        the_scope = relation.order(order_clause)
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

    end # Relation
    
    module Base
      # Class method
      def random(max_items = nil)
        relation.random(max_items)
      end

      def random_weighted(ranking_column, max_items = nil)
        relation.random_weighted(ranking_column, max_items)
      end
    end # Base

    module MethodMissingMagicks
      def method_missing(symbol, *args)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          random_weighted($1, *args)
        else
          super
        end
      end
    end
  end # ActiveRecord
end # Randumb

# Mix it in
class ActiveRecord::Relation
  include Randumb::ActiveRecord::Relation
  include Randumb::ActiveRecord::MethodMissingMagicks
end

class ActiveRecord::Base
  extend Randumb::ActiveRecord::Base
  extend Randumb::ActiveRecord::MethodMissingMagicks
end
