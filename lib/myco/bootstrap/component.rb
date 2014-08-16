
module Myco
  class Component < Module
    attr_accessor :__last__
    
    attr_reader :parent
    attr_reader :memes
    attr_reader :categories
    
    def id_scope
      @id_scope ||= (self < FileToplevel) ? self : parent.id_scope
    end
    
    def to_s
      id = self.id || "0x#{object_id.to_s 16}"
      "#<Component:#{@basename}:#{id}>"
    end
    
    def self.new super_components=[], parent=nil, filename="(dynamic)"
      super() {}.tap do |this|
        this.instance_eval {
          @super_components = super_components
          @memes      = { }
          @parent     = parent
          @filename   = filename
          @basename   = File.basename @filename
          @categories = Hash.new { |h,name|
            # category nil refers to self
            name.nil? ? self : h[name] = __new_category__(name)
          }
        }
        
        all_categories = Hash.new { |h,k| h[k] = Array.new }
        
        super_components.each do |other|
          this.send :__category__, nil # category nil refers to self
          this.include other if other
          other.categories.each { |name, cat| all_categories[name] << cat }
        end
        
        all_categories.each do |name, supers|
          this.categories[name] = this.__new_category__ name, supers
        end
        
        this.send :__category__, nil # category nil refers to self
      end
    end
    
    
    attr_reader :__id__
    alias_method :id, :__id__
    
    def __id__= id
      @__id__ = id
      id_scope.const_set :"id:#{id}", self
    end
    
    def get_by_id id
      id_scope.const_get(:"id:#{id}").instance
    end
    
    # Shadow Symbol#is_constant? to allow any symbol as constant name
    # TODO: relocate to a monkey-patch file somewhere
    class ::Symbol; def is_constant?; true; end; end
    
    
    def __category__ name
      @__current_category__ = @categories[name]
    end
    
    def __new_category__ name, super_cats=[Category]
      category = Component.new super_cats, self, @basename
      category.__id__ = :"#{self.id}.#{name}"
      category_instance = category.instance
      __meme__(name) { category_instance }
      @memes[name].memoize = true
      
      category
    end
    
    def __meme__ name, decorations=[], body=nil, scope=nil, varscope=nil, &blk
      body.scope = scope if scope && body.respond_to?(:scope=)
      meme = Meme.new @__current_category__, name, body, &blk
      
      decorations.each do |decoration|
        decorators = @categories[:decorators].instance
        raise KeyError, "Unknown decorator for #{self}##{name}: '#{decoration}'" \
          unless decorators.respond_to? decoration
        
        decorator = decorators.send decoration
        decorator.transforms.apply meme
        decorator.apply meme
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
