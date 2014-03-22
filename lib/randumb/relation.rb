require 'active_support/core_ext/module/delegation'
require 'active_record/relation'

module Randumb
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/query_methods.rb
  module ActiveRecord

    module Relation

      # If the max_items argument is omitted, one random entity will be returned.
      # If you provide the integer argument, you will get back an array of records.
      def random(max_items = nil, opts={})
        ActiveSupport::Deprecation.warn "The random() method will be depricated in randumb 1.0 in favor of the order_by_rand scope."
        relation = clone
        return random_by_id_shuffle(max_items, opts) if is_randumb_postges_case?(relation)
        scope = relation.order_by_rand(opts)

        scope = scope.limit(max_items) if override_limit?(max_items, relation)

        # return first record if method was called without parameters
        max_items ? scope.to_a : scope.first
      end

      # If ranking_column is provided, that named column wil be multiplied
      # by a random number to determine probability of order. The ranking column must be numeric.
      def random_weighted(ranking_column, max_items = nil, opts={})
        ActiveSupport::Deprecation.warn "The random_weighted() method will be depricated in randumb 1.0 in favor of the order_by_rand_weighted scope."
        relation = clone
        return random_by_id_shuffle(max_items, opts) if is_randumb_postges_case?(relation, ranking_column)
        raise_unless_valid_ranking_column(ranking_column)

        scope = relation.order_by_rand_weighted(ranking_column, opts)

        # override the limit if they are requesting multiple records
        scope = scope.limit(max_items) if override_limit?(max_items, relation)

        # return first record if method was called without parameters
        max_items ? scope.to_a : scope.first
      end


      # This was my first implementation, adding it as an option for people to use
      # and to fall back on for pesky DB one off situations...
      #    https://github.com/spilliton/randumb/issues/7
      def random_by_id_shuffle(max_items = nil, opts={})
        return_first_record = max_items.nil? # see return switch at end
        max_items ||= 1
        relation = clone
        ids = fetch_random_ids(relation, max_items, opts)

        # build new scope for final query
        the_scope = klass.includes(includes_values)

        # specifying empty selects caused bug in rails 3.0.0/3.0.1
        the_scope = the_scope.select(select_values) unless select_values.empty?

        # get the records and shuffle since the order of the ids
        # passed to where() isn't retained in the result set
        rng = random_number_generator(opts)
        records = the_scope.where(:id => ids).shuffle!(:random => rng)

        # return first record if method was called without parameters
        return_first_record ? records.first : records
      end

      def order_by_rand(opts={})
        build_order_scope(opts)
      end

      def order_by_rand_weighted(ranking_column, opts={})
        raise_unless_valid_ranking_column(ranking_column)
        is_randumb_postges_case?(self, ranking_column)
        build_order_scope(opts, ranking_column)
      end

      private

      def build_order_scope(options, ranking_column=nil)
        opts = options.reverse_merge(connection: connection, table_name: table_name)

        order_clause = if ranking_column
          Randumb::Syntax.random_weighted_order_clause(ranking_column, opts)
        else
          Randumb::Syntax.random_order_clause(opts)
        end

        if ::ActiveRecord::VERSION::MAJOR == 3 && ::ActiveRecord::VERSION::MINOR < 2
          # AR 3.0.0 support
          order(order_clause)
        else
          # keep prior orders and append random
          all_orders = (orders + [order_clause]).join(", ")
          # override all previous orders
          reorder(all_orders)
        end
      end

      # postgres won't let you do an order_by when also doing a distinct
      # let's just use the in-memory option in this case
      def is_randumb_postges_case?(relation, ranking_column=nil)
        if relation.respond_to?(:uniq_value) && relation.uniq_value && connection.adapter_name =~ /(postgres|postgis)/i
          if ranking_column
            raise Exception, "order_by_rand_weighted: not possible when using .uniq and the postgres/postgis db adapter"
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

      # Returns all matching ids from the db, shuffles them,
      # then returns an array containing at most max_ids
      def fetch_random_ids(relation, max_ids, opts={})
        # clear these for our id only query
        relation.select_values = []
        relation.includes_values = []

        # do original query but only for id field
        id_only_relation = relation.select("#{table_name}.id")

        id_results = connection.select_all(id_only_relation.to_sql)

        rng = random_number_generator(opts)
        if max_ids == 1 && id_results.count > 0
          rand_index = rng.rand(id_results.count)
          [ id_results[ rand_index ]['id'] ]
        else
          # ActiveRecord 4 requires .to_ary
          arr = id_results.respond_to?(:to_ary) ? id_results.to_ary : id_results
          arr.shuffle!(:random => rng)[0,max_ids].collect!{ |h| h['id'] }
        end
      end

      def random_number_generator(opts={})
        if seed = opts[:seed]
          Random.new(seed)
        else
          Random.new
        end
      end

      def override_limit?(max_items, relation)
        max_items && (!relation.limit_value || relation.limit_value > max_items)
      end

    end


    # Class methods
    module Base
      def random(max_items = nil, opts = {})
        relation.random(max_items, opts)
      end

      def random_weighted(ranking_column, max_items = nil, opts = {})
        relation.random_weighted(ranking_column, max_items, opts)
      end

      def random_by_id_shuffle(max_items = nil, opts = {})
        relation.random_by_id_shuffle(max_items, opts)
      end

      def order_by_rand(opts={})
        relation.order_by_rand(opts)
      end

      def order_by_rand_weighted(ranking_column, opts={})
        relation.order_by_rand_weighted(ranking_column, opts)
      end
    end


    # These get registered as class and instance methods
    module MethodMissingMagicks
      def method_missing(symbol, *args)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          ActiveSupport::Deprecation.warn "Dynamic finders will be removed in randumb 1.0 http://guides.rubyonrails.org/active_record_querying.html#dynamic-finders"
          random_weighted($1, *args)
        else
          super
        end
      end

      def respond_to?(symbol, include_private=false)
        if symbol.to_s =~ /^random_weighted_by_(\w+)$/
          ActiveSupport::Deprecation.warn "Dynamic finders will be removed in randumb 1.0 http://guides.rubyonrails.org/active_record_querying.html#dynamic-finders"
          true
        else
          super
        end
      end
    end

  end # ActiveRecord
end # Randumb
