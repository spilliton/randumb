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
      @high_on_fire = Artist.make!(:name => "High On Fire", :views => 1)
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
        @fiona_apple = Artist.make!(:name => "Fiona Apple", :views => 3)
        @magnetic_fields = Artist.make!(:name => "The Magnetic Fields", :views => 2)
      end
      
      should "respect limits and orders" do
        assert_equal @fiona_apple, Artist.order("views desc").limit(1).random
        assert_equal [@fiona_apple], Artist.order("views desc").limit(1).random(1)
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
          @tidal = Album.make!(:name => "Tidal", :artist => @fiona_apple)
          @extraordinary_machine = Album.make!(:name => "Extraordinary Machine", :artist => @fiona_apple)
          @sixty_nine_love_songs = Album.make!(:name => "69 Love Songs", :artist => @magnetic_fields)
          @snakes_for_the_divine = Album.make!(:name => "Snakes For the Divine", :artist => @high_on_fire)
        end
        
        
        should "work with includes" do
          artists =  Artist.includes(:albums).random(10)
          fiona_apple = artists.find{|a| a.name == "Fiona Apple"}
          # if I add a new album now, it shouldn't be in the albums assocation yet b/c it was already loaded
          Album.make!(:name => "When The Pawn", :artist => @fiona_apple)
          
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
  
end
