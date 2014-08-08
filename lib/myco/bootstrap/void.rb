
module Myco
  class VoidClass < ::BasicObject
    def self.new
      @singleton ||= super
    end
    
    def inspect
      "void"
    end
    
    def to_s
      ""
    end
    
    def false?
      true
    end
    
    def method_missing *args
      self
    end
    
    def hash
      nil.hash
    end
  end
  
  Void = VoidClass.new
end

# Patch the base classes to make them respond_to :false?
class ::NilClass;    def false?; true  end end
class ::TrueClass;   def false?; false end end
class ::FalseClass;  def false?; true  end end
class ::BasicObject; def false?; false end end
