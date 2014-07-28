
module Myco
  class Instance
  end
  
  class Binding
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    
    def initialize target, name, &body
      @target = target
      @name   = name
      @body   = body
    end
    
    def apply
      binding = self
      
      target.instance_eval {
        instance_variable_get(:"@#{@__category__}")[binding.name] = binding
        define_method binding.name, &binding.body if @__category__ == :bindings
      }
    end
  end
  
  class Category
    attr_reader :component
    attr_reader :name
    
    def initialize component, name
      @component  = component
      @name       = name
      @hash       = {}
    end
    
    def [] key
      @hash[key]
    end
    
    def []= key, val
      @hash[key] = val
      define_singleton_method(key) { |*a,&b| @hash[key].body.call *a, &b }
      @hash[key]
    end
  end
  
  class Component < Module
    attr_accessor :__definition__
    
    def self.new components=[], &block
      super() {}.tap do |this|
        this.send :__category__, :bindings
        
        components.each do |other|
          this.include other
          this.instance_eval &(other.send :__definition__)
        end
        
        this.send :__category__, :bindings
        
        this.send :__definition__=, block
        this.instance_eval &block
      end
    end
    
    def __category__ name
      ivar_name = :"@#{name}"
      @__category__ = name
      
      category = instance_variable_get(ivar_name) || Category.new(self, name)
      instance_variable_set(ivar_name, category)
      define_method(category.name) { category }
    end
    
    def __binding__ name, decorations, &block
      binding = Binding.new self, name, &block
      decorations.each do |decoration|
        decorator = (@decorators || {})[decoration]
        raise KeyError, "Unknown decorator: #{decoration}." unless decorator
        decorator.body.call.apply binding
      end
      binding.apply
    end
    
    def new
      obj = Instance.new
      obj.extend self
      obj.__signal__ :creation if obj.respond_to? :__signal__
      obj
    end
  end
  
  BasicObject = Component.new do
  end
  
  RubyEval = Component.new do
    def from_string string
      eval string
    end
  end
  
end
