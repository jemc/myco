
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/compiler'
require_relative 'lib/myco/eval'

require 'pp'

class Myco
  module Foo; end
  module Bar; end
  module Baz; end
  
  class Instance < Object
    def from_string string
      eval string
    end
  end
  
  class Component < Module
    def self.new components
      super().tap do |this|
        components.each do |other|
          this.include other
        end
      end
    end
    
    def create
      obj = Instance.new
      obj.extend self
      obj
    end
  end
  
  Myco.eval <<-code
    A: Foo,Bar,Baz @@@
      
    @@@
  code
  
  p A.singleton_class.ancestors
  
  pp A
  
end