require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation

      # If the max_items argument is omitted, one random entity will be returned.
      # If ranking_column is provided, that named column will be used, multiplied
      # by the ranking scalar, to determine probability of order.
      #
      # * The ranking column must be numeric
      # * Larger values of ranking_scalar will minimize randomness and select more by the ranking column
      # * Setting ranking_scalar to values less than 1 will minimize the impact of ranking_column.
      def random(max_items = nil)
        random_weighted([], max_items)
      end

      def random_weighted(ranking_columns, max_items = nil, ranking_scalar = 1)
        relation = clone
        if connection.adapter_name =~ /sqlite/i || connection.adapter_name =~ /postgres/i
          rand_syntax = "RANDOM()"
        elsif connection.adapter_name =~ /mysql/i
          rand_syntax = "RAND()"
        else
          raise Exception, "ActiveRecord adapter: '#{connection.adapter_name}' not supported by randumb.  Send a pull request or open a ticket: https://github.com/spilliton/randumb"
        end

        order_clause = if ranking_columns.nil? || ranking_columns.empty?
                         rand_syntax
                       else
                         columns = [ranking_columns].flatten.join(" * ") # <- supports singular column names
                         "(#{rand_syntax} * #{columns} * #{ranking_scalar.to_i}) DESC"
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

      def random_weighted(ranking_columns, max_items = nil, ranking_scalar = 1)
        relation.random_weighted(ranking_columns, max_items, ranking_scalar)
      end
    end # Base

    module MethodMissingMagicks
      def method_missing(symbol, *args)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          random_weighted($1.split("_and_"), *args)
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
