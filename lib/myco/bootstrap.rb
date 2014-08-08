
module Myco
  class Instance < ::BasicObject
    include ::Kernel
    
    def to_s
      "#<Instance(#{component})>"
    end
    
    def inspect
      to_s
    end
    
    attr_reader :component
    
    def initialize component
      @component = component
    end
    
    def memes
      @component.memes
    end
    
    # Commandeer a few methods implemented in Kernel
    %i{ extend respond_to? method_missing hash }.each do |sym|
      define_method sym do |*args, &blk|
        ::Kernel.instance_method(sym).bind(self).call(*args)
      end
    end
  end
  
  class Meme
    attr_accessor :target
    attr_accessor :name
    attr_accessor :body
    attr_accessor :memoize
    
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
    end
    
    def bind
      meme = self
      target.memes[@name] = meme
      
      target.send :define_method, @name do |*args, &blk|
        meme.call_on(self, *args, &blk)
      end
    end
    
    def call_on obj, *args, &blk
      memo_key = [obj.hash, args.hash, blk.hash]
      if @memoize && result = @memos[memo_key]
        return result
      end
      
      result = if @body.is_a? Rubinius::Executable
        @body.invoke @name, @target, obj, args, blk
      elsif @body.respond_to? :call
        @body.call *args, &blk
      else
        raise "The body of #{self} is not executable"
      end
      
      @memos[memo_key] = result
    end
    
    def result *args, &blk
      call_on target.instance, *args, &blk
    end
  end
  
  class Component < Module
    attr_reader :memes
    
    # def to_s
    #   id = "0x#{object_id.to_s 16}"
    #   "#<Component(#{@super_components.join ','}):#{id}>"
    # end
    
    def self.new super_components=[], scope=nil
      super() {}.tap do |this|
        this.instance_eval {
          @super_components = super_components
          @memes      = { }
          @@categories ||= { }
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
        @__current_category__ = @@categories[name] ||= ( # TODO: don't use cvar
          category = Component.new([Category]) { }
          category_instance = category.instance
          category_instance.instance_variable_set(:@__parent_component__, self)
          category_instance_proc = Proc.new { category_instance }
          __meme__(name, [], category_instance_proc)
          @memes[name].memoize = true
          
          category
        )
      end
    end
    
    def __meme__ name, decorations, body, scope=nil, varscope=nil
      body.scope = scope if scope && body.respond_to?(:scope=)
      meme = Meme.new @__current_category__, name, body
      
      decorations.each do |decoration|
        decorator = @@categories[:decorators].memes[decoration] # TODO: don't use cvar
        raise KeyError, "Unknown decorator for #{self}##{name}: '#{decoration}'" \
          unless decorator
        
        decorator.result.apply meme
      end
      meme.bind
      
      meme
    end
    
    def instance
      if !@instance
        @instance = Instance.new(self)
        @instance.extend self
        @instance.__signal__ :creation if @instance.respond_to? :__signal__
      end
      @instance
    end
  end
  
  EmptyObject = Component.new
  
end
