$:.unshift '.'; require File.dirname(__FILE__) + '/test_helper'

class WeightedTest < Test::Unit::TestCase

  should "raise exception when called with a non-existent column" do
    assert_raises(ArgumentError) do
      Artist.order_by_rand_weighted(:blah)
    end
    assert_raises(ArgumentError) do
      Artist.random_weighted_by_blah
    end
  end

  should "raise exception when called with a non-numeric column" do
    assert_raises(ArgumentError) do
      Artist.order_by_rand_weighted(:name)
    end
    assert_raises(ArgumentError) do
      Artist.random_weighted_by_name
    end
  end

  # ActiveRecord 3.0 doesnt have uniq scope
  if Artist.respond_to?(:uniq)
    if ENV["DB"] == "postgres"
      should "raise exception if being called with uniq/postgres" do
        assert_raises(Exception) do
          Artist.uniq.order_by_rand_weighted(:views)
        end
      end
    else
      should "work with uniq if not postgres" do
        assert_nil Artist.uniq.random_weighted_by_views
      end
    end
  end

  should "not blow up with integer columns and float column types" do
    assert_nil Artist.random_weighted_by_views
    assert_nil Artist.random_weighted_by_rating
  end

  should "not interfere with active record dynamic methods that use method_missing" do
    @artist = FactoryGirl.create(:artist, :name => 'Spiritualized')
    assert_equal @artist, Artist.find_by_name('Spiritualized')
  end

  should "respond to respond_to?" do
    assert Artist.respond_to?(:random_weighted_by_views)
    assert Artist.respond_to?(:random_weighted_by_xxxxxx)
    assert Artist.at_least_three_views.respond_to?(:random_weighted_by_xxxxxx)
  end

  should "not interfere with active record dynamic methods that use respond_to?" do
    assert Artist.respond_to?(:find_by_name)
  end


  context "order by ranking_column" do
    setup do
      @view_counts = [1, 2, 3, 4, 5]
      @view_counts.each { |views| FactoryGirl.create(:artist, :views => views) }
    end

    should "order by ranking column with explicit method call" do
      assert_hits_per_views do
        Artist.random_weighted("views").views
      end
      assert_hits_per_views do 
        Artist.order_by_rand_weighted("views").first.views
      end
    end

    should "order by ranking column with method_missing" do
      assert_hits_per_views do
        Artist.random_weighted_by_views.views
      end
    end

    should "order by ranking column with explicit method call and max_items" do
      assert_hits_per_views do
        result = Artist.random_weighted("views", 5)
        assert(result.size == 5)
        result.first.views
      end

      assert_hits_per_views do 
        result = Artist.order_by_rand_weighted("views").limit(5).all
        assert(result.size == 5)
        result.first.views
      end
    end

    should "order by ranking column with method_missing using max_items" do
      assert_hits_per_views do
        result = Artist.random_weighted_by_views(10)
        assert(result.size == 5)
        result.first.views
      end
    end

    should "LAST order should fail" do
      assert_raises(MiniTest::Assertion) do
        assert_hits_per_views do
          result = Artist.random_weighted_by_views(3)
          assert(result.size == 3)
          result.last.views
        end
      end

      assert_raises(MiniTest::Assertion) do
        assert_hits_per_views do
          result = Artist.order_by_rand_weighted(:views).limit(3)
          assert(result.size == 3)
          result.last.views
        end
      end
    end

    should "order by ranking column with method_missing using 1 max_items" do
      assert_hits_per_views do
        result = Artist.random_weighted_by_views(1)
        assert(result.size == 1)
        result.first.views
      end

      assert_hits_per_views do
        result = Artist.order_by_rand_weighted(:views).limit(1)
        assert(result.size == 1)
        result.first.views
      end
    end
  end

  def assert_hits_per_views
    hits_per_views = Hash.new
    @view_counts.each { |views| hits_per_views[views] = 0 }
    
    1000.times do
      hits_per_views[yield] += 1
    end
    last_count = 0
    @view_counts.each do |views|
      hits = hits_per_views[views]
      assert(hits >= last_count, "#{hits} > #{last_count} : There were an unexpected number of visits: #{hits_per_views.to_yaml}")
      last_count = hits
    end
  end


end