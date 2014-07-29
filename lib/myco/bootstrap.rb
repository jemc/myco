
module Myco
  class Instance
    def self.to_s
      "#{super}(#{ancestors[1]})"
    end
    
    attr_reader :component
    
    def initialize component
      @component = component
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
      
      @memos  = {} # TODO: use weak map to avoid consuming endless memory
      @new_result_name = :"__binding_new_result_#{name}__" # TODO: do better...
    end
    
    def bind
      binding = self
      
      lmemos = @memos
      lbody  = @body
      lname  = @name
      lnname = @new_result_name
      
      target.instance_eval do
        @bindings ||= {}
        @bindings[lname] = binding
        
        define_method(lnname, &lbody)
        define_method(lname) do |*args, &blk|
          lmemos[[self.hash, args.hash]] ||= send(lnname, *args, &blk)
        end
      end
    end
    
    def result *args, &blk
      target.instance.send(@name, *args, &blk)
    end
    
  end
  
  class Component < Module
    attr_accessor :__definition__
    attr_reader :bindings
    
    def self.new super_components=[], &block
      super() {}.tap do |this|
        this.instance_eval {
          @super_components = super_components
          @bindings   = { }
          @categories = { }
        }
        
        super_components.each do |other|
          this.send :__category__, nil # category nil refers to self
          this.include other
          this.instance_eval &(other.send :__definition__)
        end
        
        this.send :__category__, nil # category nil refers to self
        this.send :__definition__=, block
        this.instance_eval &block
      end
    end
    
    def __category__ name
      if name == nil
        @__current_category__ = self
      else
        @categories[name] ||= (
          category = Component.new([Category]) { }
          category_instance = category.instance
          __binding__(name, []) { category_instance }
          @__current_category__ = category
          @__decorators__ = category_instance if name == :decorators
          category
        )
      end
    end
    
    def __binding__ name, decorations, &block
      binding = Binding.new @__current_category__, name, &block
      
      decorations.each do |decoration|
        decorator = @__decorators__.send(decoration)
        # raise KeyError, "Unknown decorator: '#{decoration}'" unless decorator
        
        decorator.apply binding
      end
      binding.bind
    end
    
    def instance
      if !@instance
        @instance = Instance.new(self)
        @instance.extend self
        @instance.__signal__ :creation if @instance.respond_to? :__signal__
      end
      @instance
    end
    
    def new
      instance
    end
  end
  
  BasicObject = Component.new do
  end
  
  Category = Component.new([BasicObject]) do
  end
  
end
