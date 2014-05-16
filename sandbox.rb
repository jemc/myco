
require_relative 'lib/myco/toolset'
require_relative 'lib/myco/parser'
require_relative 'lib/myco/eval'

require 'pp'

module Myco
  module Foo; end
  module Bar; end
  module Baz; end
  
  class Instance < Object
    def from_string string
    end
    
    def __component_init__
    end
    
    def __signal__ signal, *args
      sym = :"__on_#{signal}__"
      send sym, *args
    end
  end
  
  class Binding
    attr_reader :component
    attr_reader :name
    attr_reader :decorators
    attr_reader :body
    
    def initialize component, name, decorators, &body
      @component  = component
      @name       = name
      @decorators = decorators
      @body       = body
      
      @component.send :__bind__, name, decorators, self
    end
  end
  
  class Component < Module
    def self.new components=[], &block
      super() {}.tap do |this|
        components.each do |other|
          this.include other
        end
        
        this.send :__bind_category__, :bindings
        
        this.instance_eval &block
      end
    end
    
    def __bind_category__ name
      @__bind_category__ = name
      attr_name = :"@#{name}"
      instance_variable_set(attr_name, instance_variable_get(attr_name) || {})
    end
    
    def __bind__ name, decorators, binding
      name = :"__on_#{name}__" if decorators.include? :on
      
      instance_variable_get(:"@#{@__bind_category__}")[name] == binding
      
      define_method name, &binding.body if @__bind_category__ == :bindings
    end
    
    def new
      obj = Instance.new
      obj.extend self
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
  
  Myco.eval File.read './sandbox.my'
  
end