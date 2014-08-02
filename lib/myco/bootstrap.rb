
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
  
  class Meme
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    
    def to_s
      "#<#{self.class}:#{self.name.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize target, name, body
      @target = target
      @name   = name
      @body   = body
      
      @memos  = {} # TODO: use weak map to avoid consuming endless memory
      @new_result_name = :"__meme_new_result_#{name}__" # TODO: do better...
    end
    
    def bind
      meme = self
      
      lmemos = @memos
      lbody  = @body
      lname  = @name
      lnname = @new_result_name
      ltarget = @target
      ltarget = @target.component if @target.is_a? Instance
      
      
      target.instance_eval do
        @memes ||= {}
        @memes[lname] = meme
        
        if lbody.is_a? Rubinius::Executable
          Rubinius.add_method lnname, lbody, ltarget, :public
        else
          define_method lnname, &lbody
        end
        
        define_method lname do |*args, &blk|
          lmemos[[self.hash, args.hash]] ||= send(lnname, *args, &blk)
        end
      end
    end
    
    def result *args, &blk
      target.instance.send(@name, *args, &blk)
    end
    
  end
  
  class Component < Module
    attr_reader :memes
    
    def self.new super_components=[], scope=nil
      super() {}.tap do |this|
        this.instance_eval {
          @super_components = super_components
          @memes      = { }
          @categories = { }
        }
        
        super_components.each do |other|
          this.send :__category__, nil # category nil refers to self
          this.include other if other
          other.instance # TODO: merge super_components categories instead
        end
        
        this.send :__category__, nil # category nil refers to self
      end
    end
    
    def __category__ name
      if name == nil
        @__current_category__ = self
      else
        @categories[name] ||= (
          category = Component.new([Category]) { }
          category_instance = category.instance
          category_instance_proc = Proc.new { category_instance }
          __meme__(name, [], category_instance_proc)
          
          @__current_category__ = category
          @@__decorators__ = category_instance if name == :decorators # TODO: remove
          category
        )
      end
    end
    
    def __meme__ name, decorations, body, scope=nil, varscope=nil
      body.scope = scope if scope && body.respond_to?(:scope=)
      meme = Meme.new @__current_category__, name, body
      
      decorations.each do |decoration|
        decorator = @@__decorators__.send(decoration) # TODO: don't use cvar
        # raise KeyError, "Unknown decorator: '#{decoration}'" unless decorator
        
        decorator.apply meme
      end
      meme.bind
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
