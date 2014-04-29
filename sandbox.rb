
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
    
    def __signal__ signal, *args
      sym = :"__on_#{signal}__"
      send sym, *args
    end
    
    def __bind__ sym, decorations, &block
      sym = :"__on_#{sym}__" if decorations.include? :on
      
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
      obj.__signal__ :creation
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
    Object {
      on creation: print("Hello, world!")
      
      print: |str| STDOUT.puts(str)
    }
  code
  
end