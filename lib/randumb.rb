module Randumb
  
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def random
      puts "random extended!"
    end
  end
  
  
end


ActiveRecord::Base.class_eval do
  include Randumb
end
