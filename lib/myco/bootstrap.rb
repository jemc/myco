
module Myco
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
  
  class Category
    attr_reader :component
    attr_reader :name
    
    def initialize component, name
      @component  = component
      @name       = name
      @hash       = {}
    end
    
    def embed
      @component.send :__category__, self
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
    def self.new components=[], &block
      super() {}.tap do |this|
        components.each do |other|
          this.include other
        end
        
        Category.new(this, :bindings).embed
        
        this.instance_eval &block
      end
    end
    
    def __category__ cat
      @__category__ = cat.name
      attr_name = :"@#{cat.name}"
      instance_variable_set(attr_name, instance_variable_get(attr_name) || cat)
      define_method(cat.name) { cat }
    end
    
    def __bind__ name, decorators, binding
      name = :"__on_#{name}__" if decorators.include? :on
      
      instance_variable_get(:"@#{@__category__}")[name] = binding
      
      define_method name, &binding.body if @__category__ == :bindings
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
  
end
