$:.unshift '.'; require File.dirname(__FILE__) + '/test_helper'

class RandumbTest < Test::Unit::TestCase

  def assert_equal_for_both_methods(expected, obj, *params)
    assert_equal expected, obj.send(:random, *params), "when calling random"
    assert_equal expected, obj.send(:random_by_id_shuffle, *params), "when calling random_by_id_shuffle"
  end

  should "should return empty when no record in table" do
    assert_equal 0, Artist.count

    assert_equal_for_both_methods nil, Artist
    # above is equivalent to:
    # assert_equal nil, Artist.random
    # assert_equal nil, Artist.random_by_id_shuffle
    assert_nil Artist.order_by_rand.first

    assert_equal_for_both_methods [], Artist, 1
    # above is equivalent to:
    # assert_equal [], Artist.random(1)
    # assert_equal [], Artist.random_by_id_shuffle(1)
    assert_equal [], Artist.order_by_rand.limit(1).all

    assert_equal_for_both_methods nil, Artist.limit(50)
  end

  context "1 record in the table" do
    setup do
      @high_on_fire = FactoryGirl.create(:artist, :name => "High On Fire", :views => 1)
    end

    should "select only 1 record even when you request more" do
      assert_equal 1, Artist.count

      assert_equal_for_both_methods @high_on_fire, Artist
      assert_equal @high_on_fire, Artist.order_by_rand.first

      assert_equal_for_both_methods [@high_on_fire], Artist, 1
      assert_equal_for_both_methods [@high_on_fire], Artist, 30
      assert_equal [@high_on_fire], Artist.limit(30).order_by_rand.all
    end

    should "not return a record that doesnt match where" do
      assert_equal_for_both_methods nil, Artist.where(:name => "The Little Gentlemen")
    end

    context "3 records in table" do
      setup do
        @fiona_apple = FactoryGirl.create(:artist, :name => "Fiona Apple", :views => 3)
        @magnetic_fields = FactoryGirl.create(:artist, :name => "The Magnetic Fields", :views => 2)
      end

      should "apply randomness after other orders when using sql method" do
        assert_equal @fiona_apple, Artist.order("views desc").random
        assert_equal [@fiona_apple, @magnetic_fields], Artist.order("views desc").random(2)
      end

      should "take smaller limit if one is provided in scope" do
        assert_equal 2, Artist.limit(2).random(3).length
        assert_equal 2, Artist.limit(2).random_by_id_shuffle(3).length

        assert_equal 2, Artist.limit(3).random(2).length
        assert_equal 2, Artist.limit(3).random_by_id_shuffle(2).length
      end

      should "respect selecting certain columns" do
        assert_equal 3, Artist.find(@fiona_apple.id).views

        artists = Artist.select(:name).random(3)
        assert_equal false, artists.first.name.nil?
        assert_raise (ActiveModel::MissingAttributeError) {artists.first.views}

        artists = Artist.select(:name).order_by_rand.limit(3)
        assert_equal false, artists.first.name.nil?
        assert_raise (ActiveModel::MissingAttributeError) {artists.first.views}

        artists = Artist.select(:name).random_by_id_shuffle(3)
        assert_equal false, artists.first.name.nil?
        assert_raise (ActiveModel::MissingAttributeError) {artists.first.views}
      end

      should "respect scopes" do
        assert_equal_for_both_methods [@fiona_apple], Artist.at_least_three_views, 3
        assert_equal [@fiona_apple], Artist.at_least_three_views.order_by_rand.limit(3)
      end

      should "select only as many as in the db if we request more" do
        random_artists = Artist.random(10)
        assert_equal 3, random_artists.length
        assert_equal true, random_artists.include?(@high_on_fire)
        assert_equal true, random_artists.include?(@fiona_apple)
        assert_equal true, random_artists.include?(@magnetic_fields)

        random_artists = Artist.random_by_id_shuffle(10)
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


        should "work with includes for default method" do
          artists = Artist.includes(:albums).random(10)
          fiona_apple = artists.find { |a| a.name == "Fiona Apple" }
          # if I add a new album now, it shouldn't be in the albums assocation yet b/c it was already loaded
          FactoryGirl.create(:album, :name => "When The Pawn", :artist => @fiona_apple)

          assert_equal 2, fiona_apple.albums.length
          assert_equal 3, @fiona_apple.reload.albums.length
        end

        should "work with includes for shuffle method" do
          artists = Artist.includes(:albums).random_by_id_shuffle(10)
          fiona_apple = artists.find { |a| a.name == "Fiona Apple" }
          # if I add a new album now, it shouldn't be in the albums assocation yet b/c it was already loaded
          FactoryGirl.create(:album, :name => "When The Pawn", :artist => @fiona_apple)

          assert_equal 2, fiona_apple.albums.length
          assert_equal 3, @fiona_apple.reload.albums.length
        end

        should "work with joins for default method" do
          albums = Album.joins(:artist).where("artists.views > 1").random(3)

          assert_equal 3, albums.length
          assert_equal false, albums.include?(@snakes_for_the_divine)
          assert_equal true, albums.include?(@tidal)
          assert_equal true, albums.include?(@extraordinary_machine)
          assert_equal true, albums.include?(@sixty_nine_love_songs)
        end

        should "work with joins for shuffle method" do
          albums = Album.joins(:artist).where("artists.views > 1").random_by_id_shuffle(3)

          assert_equal 3, albums.length
          assert_equal false, albums.include?(@snakes_for_the_divine)
          assert_equal true, albums.include?(@tidal)
          assert_equal true, albums.include?(@extraordinary_machine)
          assert_equal true, albums.include?(@sixty_nine_love_songs)
        end

        # ActiveRecord 3.0 does not have this
        if Artist.respond_to?(:uniq)
          should "work with uniq" do
            assert_equal 2, Artist.uniq.random(2).length
            assert_equal 2, Artist.uniq.random_by_id_shuffle(2).length
            assert_not_nil Artist.uniq.random
            assert_not_nil Artist.uniq.random_by_id_shuffle
          end
        end

      end

    end

  end

  context "2 records in table" do
    setup do
      @hum = FactoryGirl.create(:artist, :name => "Hum", :views => 3)
      @minutemen = FactoryGirl.create(:artist, :name => "Minutemen", :views => 2)
    end

    should "eventually render the 2 possible orders using default method" do
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

    should "eventually render the 2 possible orders using shuffle method" do
      order1 = [@hum, @minutemen]
      order2 = [@minutemen, @hum]
      order1_found = false
      order2_found = false
      100.times do
        order = Artist.random_by_id_shuffle(2)
        order1_found = true if order == order1
        order2_found = true if order == order2
        break if order1_found && order2_found
      end
      assert order1_found
      assert order2_found
    end

    context "using seed" do
      setup do
        @seed = 123
      end

      should "always return the same order using default method" do
        seeded_order = Artist.random(2, seed: @seed)
        10.times do
          assert_equal seeded_order, Artist.random(2, seed: @seed)
        end

        10.times do 
          assert_equal seeded_order, Artist.order_by_rand(seed: @seed).limit(2)
        end
      end

      should "always return the same order using shuffle method" do
        seeded_order = Artist.random_by_id_shuffle(2, seed: @seed)
        10.times do
          assert_equal seeded_order, Artist.random_by_id_shuffle(2, seed: @seed)
        end
      end
    end
  end
end
