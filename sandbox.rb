
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
    
    def __component_init__
      
    end
    
    def __bind__ sym, &block
      p block.arity
      define_singleton_method sym, &block
    end
  end
  
  class Component < Module
    def self.new components=[], &block
      super() {
          define_method :__component_init__, &block
        }.tap do |this|
        components.each do |other|
          this.include other
        end
      end
    end
    
    def new
      obj = Instance.new
      obj.extend self
      obj.__component_init__
      obj
    end
  end
  
  Object = Component.new do
  end
  
  RubyEval = Component.new do
    def from_string string
      eval string
    end
  end
  
  Myco.eval <<-code
    A < Object {
      foo: |x| x
    }
  code
  
  p A.ancestors
  
  pp a = A.new
  pp a.foo 77
  
end