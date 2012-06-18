require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord
    
    module Relation

      # If the max_items argument is omitted, one random entity will be returned.
      def random(max_items = nil)
        random_weighted(nil, max_items)
      end

      # If ranking_column is provided, that named column wil be multiplied
      # by a random number to determine probability of order. The ranking column must be numeric.
      def random_weighted(ranking_column, max_items = nil)
        relation = clone
        if connection.adapter_name =~ /sqlite/i || connection.adapter_name =~ /postgres/i
          rand_syntax = "RANDOM()"
        elsif connection.adapter_name =~ /mysql/i
          rand_syntax = "RAND()"
        else
          raise Exception, "ActiveRecord adapter: '#{connection.adapter_name}' not supported by randumb.  Send a pull request or open a ticket: https://github.com/spilliton/randumb"
        end

        order_clause = if ranking_column.nil?
                         rand_syntax
                       else
                         "(#{rand_syntax} * #{ranking_column}) DESC"
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
