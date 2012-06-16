$:.unshift '.';require File.dirname(__FILE__) + '/test_helper'

class RandumbTest < Test::Unit::TestCase

  context "no records in the table" do
    setup do
      Artist.delete_all("id > -1")
    end

    should "should return empty array" do
      assert_equal 0, Artist.count
      assert_equal nil, Artist.random
      assert_equal [], Artist.random(1)
      assert_equal nil, Artist.limit(50).random
    end

  end


  context "1 record in the table" do
    setup do
      Artist.delete_all("id > -1")
      @high_on_fire = FactoryGirl.create(:artist, :name => "High On Fire", :views => 1)
    end

    should "select only 1 record even when you request more" do
      assert_equal 1, Artist.count
      assert_equal @high_on_fire, Artist.random
      assert_equal [@high_on_fire], Artist.random(1)
      assert_equal [@high_on_fire], Artist.random(30)
    end

    should "not return a record that doesnt match where" do
      assert_equal nil, Artist.where(:name => "Wang Is Burning").random
    end

    context "3 records in table" do
      setup do
        @fiona_apple = FactoryGirl.create(:artist, :name => "Fiona Apple", :views => 3)
        @magnetic_fields = FactoryGirl.create(:artist, :name => "The Magnetic Fields", :views => 2)
      end

      should "apply randomness after other orders" do
        assert_equal @fiona_apple, Artist.order("views desc").random
        assert_equal [@fiona_apple, @magnetic_fields], Artist.order("views desc").random(2)
      end

      should "take smaller limit if one is provided in scope" do
        assert_equal 2, Artist.limit(2).random(3).length
        assert_equal 2, Artist.limit(3).random(2).length
      end

      should "respect selecting certain columns" do
        assert_equal 3, Artist.find(@fiona_apple.id).views

        artists = Artist.select(:name).random(3)
        assert_equal false, artists.first.name.nil?
        assert_raise (ActiveModel::MissingAttributeError) { artists.first.views }
      end

      should "respect scopes" do
        assert_equal [@fiona_apple], Artist.at_least_three_views.random(3)
      end

      should "select all 3 if we want them" do
        random_artists = Artist.random(10)
        assert_equal 3, random_artists.length
        assert_equal true, random_artists.include?(@high_on_fire)
        assert_equal true, random_artists.include?(@fiona_apple)
        assert_equal true, random_artists.include?(@magnetic_fields)
      end

      context "with some albums" do
        setup do
          @tidal = FactoryGirl.create(:album, :name => "Tidal", :artist => @fiona_apple)
          @extraordinary_machine = FactoryGirl.create(:album, :name => "Extraordinary Machine", :artist => @fiona_apple)
          @sixty_nine_love_songs = FactoryGirl.create(:album, :name => "69 Love Songs", :artist => @magnetic_fields)
          @snakes_for_the_divine = FactoryGirl.create(:album, :name => "Snakes For the Divine", :artist => @high_on_fire)
        end


        should "work with includes" do
          artists = Artist.includes(:albums).random(10)
          fiona_apple = artists.find{|a| a.name == "Fiona Apple"}
          # if I add a new album now, it shouldn't be in the albums assocation yet b/c it was already loaded
          FactoryGirl.create(:album, :name => "When The Pawn", :artist => @fiona_apple)

          assert_equal 2, fiona_apple.albums.length
          assert_equal 3, @fiona_apple.reload.albums.length
        end

        should "work with joins" do
          albums = Album.joins(:artist).where("artists.views > 1").random(3)

          assert_equal 3, albums.length
          assert_equal false, albums.include?(@snakes_for_the_divine)
          assert_equal true, albums.include?(@tidal)
          assert_equal true, albums.include?(@extraordinary_machine)
          assert_equal true, albums.include?(@sixty_nine_love_songs)
        end
      end

    end

  end

  context "2 records in table" do
    setup do
      @hum = FactoryGirl.create(:artist, :name => "Hum", :views => 3)
      @minutemen = FactoryGirl.create(:artist, :name => "Minutemen", :views => 2)
    end

    should "eventually render the 2 possible orders" do
      order1 = [@hum, @minutemen]
      order2 = [@minutemen, @hum]
      order1_found = false
      order2_found = false
      100.times do
        order = Artist.random(2)
        order1_found = true if order == order1
        order2_found = true if order == order2
        break if order1_found && order2_found
      end
      assert order1_found
      assert order2_found
    end
  end

  context "order by ranking_column" do
    setup do
      @view_counts = [1, 2, 4, 8, 16, 32]
      @view_counts.each { |views| FactoryGirl.create(:artist, :views => views) }
    end

    should "order by ranking column with explicit method call" do
      assert_hits_per_views do
        Artist.random_weighted("views").views
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
    end

    should "order by ranking column with method_missing using max_items" do
      assert_hits_per_views do
        result = Artist.random_weighted_by_views(5)
        assert(result.size == 5)
        result.first.views
      end
    end

    def assert_hits_per_views
      hits_per_views = Hash.new
      @view_counts.each { |views| hits_per_views[views] = 0 }
      2000.times do
        hits_per_views[yield] += 1
      end
      last_count = 0
      puts hits_per_views.to_yaml
      @view_counts.each do |views|
        hits = hits_per_views[views]
        assert(hits >= last_count, "#{hits} > #{last_count} : There were an unexpected number of visits: #{hits_per_views.to_yaml}")
        last_count = hits
      end
    end
  end
end
