$:.unshift '.';require File.dirname(__FILE__) + '/test_helper'

class TestRandumb < Test::Unit::TestCase
  
  context "no records in the table" do
    setup do
      Artist.delete_all("id > -1")
    end
    
    should "should return empty array" do
      assert_equal 0, Artist.count
      assert_equal [], Artist.random
      assert_equal [], Artist.limit(50).random
    end
    
  end
  
  
  context "1 record in the table" do
    setup do
      Artist.delete_all("id > -1")
      @high_on_fire = Artist.make!(:name => "High On Fire", :views => 1)
    end
    
    should "select only 1 record even when you request more" do
      assert_equal 1, Artist.count
      assert_equal [@high_on_fire], Artist.random
      assert_equal [@high_on_fire], Artist.random(30) 
    end
    
    should "not return a record that doesnt match where" do
      assert_equal [], Artist.where(:name => "Wang Is Burning").random
    end
    
    context "3 records in table" do
      setup do
        @fiona_apple = Artist.make!(:name => "Fiona Apple", :views => 3)
        @magnetic_fields = Artist.make!(:name => "The Magnetic Fields", :views => 2)
      end
      
      should "respect limits and orders" do
        assert_equal [@fiona_apple], Artist.order("views desc").limit(1).random
      end
    end
    
  end
  
end