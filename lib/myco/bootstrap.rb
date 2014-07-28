
module Myco
  class Instance
    def self.to_s
      "#{super}(#{ancestors[1]})"
    end
  end
  
  class Binding
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    
    def to_s
      "#<#{self.class}:#{self.name.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize target, name, &body
      @target = target
      @name   = name
      @body   = body
    end
    
    def apply
      binding = self
      
      target.instance_eval {
        @bindings ||= {}
        @bindings[binding.name] = binding
        define_method binding.name, &binding.body if binding.target.is_a? Module
      }
    end
  end
  
  class Component < Module
    attr_accessor :__definition__
    attr_reader :bindings
    
    def self.new components=[], &block
      super() {}.tap do |this|
        this.instance_eval {
          @bindings   = { }
          @categories = { nil=>this }
        }
        
        components.each do |other|
          this.include other
          this.instance_eval &(other.send :__definition__)
          this.send :__category__, nil # category nil refers to self
        end
        
        this.send :__definition__=, block
        this.instance_eval &block
      end
    end
    
    def __category__ name
      ivar_name = :"@#{name}"
      @__category__ = name
      
      category = @categories[name]
      unless category
        category = Component.new([Category]){}
        @categories[name] = category
      end
      unless name.nil? # category nil refers to self
        category_instance = category.new
        define_method(name) { category_instance }
      end
    end
    
    def __binding__ name, decorations, &block
      target = @categories[@__category__] || self
      binding = Binding.new target, name, &block
      
      decorations.each do |decoration|
        decorator = (@categories[:decorators] || {}).bindings[decoration]
        raise KeyError, "Unknown decorator: '#{decoration}'" unless decorator
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
  
  Category = Component.new([BasicObject]) do
  end
  
end
