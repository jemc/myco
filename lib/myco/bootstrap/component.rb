
module Myco
  class Component < Module
    attr_reader :memes
    
    attr_accessor :__last__
    
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
    
    def __id__ name
      @__id__ = name
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
        
        decorator.result.transforms.apply meme
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
end
