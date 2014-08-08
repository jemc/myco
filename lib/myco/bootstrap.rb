
module Myco
  class Instance
    def self.to_s
      "#{super}(#{ancestors[1]})"
    end
    
    attr_reader :component
    
    def initialize component
      @component = component
    end
    
    def memes
      @component.memes
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
    end
    
    def bind
      meme = self
      target.memes[@name] = meme
      
      target.send :define_method, @name do |*args, &blk|
        meme.call_on(self, *args, &blk)
      end
    end
    
    def call_on obj, *args, &blk
      @memos[[obj.hash, args.hash]] ||= begin
        if @body.is_a? Rubinius::Executable
          @body.invoke @name, @target, obj, args, blk
        elsif @body.respond_to? :call
          @body.call *args, &blk
        else
          raise "The body of #{self} is not executable"
        end
      end
    end
    
    def result *args, &blk
      call_on target.instance, *args, &blk
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
          category_instance.instance_variable_set(:@__parent_component__, self)
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
        decorators = @@__decorators__ # TODO: don't use cvar
        raise KeyError, "Unknown decorator in #{self}: '#{decoration}'" \
          unless decorators.respond_to? decoration
        
        decorators.send(decoration).apply meme
      end
      meme.bind
    end
    
    def memes
      @memes
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
  
  BasicObject = Component.new
  
end
