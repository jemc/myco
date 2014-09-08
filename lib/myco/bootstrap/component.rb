
module Myco
  class Component < Module
    attr_accessor :__last__
    
    attr_reader :parent
    attr_reader :memes
    attr_reader :categories
    
    def to_s
      id = "0x#{object_id.to_s 16}"
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
          @dirname    = File.dirname  @filename
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
    
    def __category__ name
      @categories[name]
    end
    
    def __new_category__ name, super_cats=[Category]
      category = Component.new super_cats, self, @basename
      category_instance = category.instance
      declare_meme(name) { category_instance }
      @memes[name].cache = true
      
      category
    end
    
    def declare_meme name, decorations=[], body=nil, scope=nil, varscope=nil, &blk
      body.scope = scope if scope && body.respond_to?(:scope=)
      meme = Meme.new self, name, body, &blk
      
      decorations.each do |decoration, arguments|
        search_component = self<Category ? parent : self
        decorators = search_component.categories[:decorators].instance
        
        raise KeyError, "Unknown decorator for #{self}##{name}: #{decoration}" \
          unless decorators.respond_to?(decoration)
        decorator = decorators.send(decoration)
        decorator.transforms.apply meme, *arguments
        decorator.apply meme, *arguments
      end
      meme.bind
      
      meme
    end
    
    def instance
      if !@instance
        @instance = Instance.new(self)
        @instance.extend self
        yield @instance if block_given?
        @instance.__signal__ :creation if @instance.respond_to? :__signal__
      else
        yield @instance if block_given?
      end
      
      @instance
    end
    
    def new parent=nil, **kwargs
      Component.new([self], parent, @filename).instance { |instance|
        kwargs.each { |key,val| instance.send :"#{key}=", val }
      }
    end
  end
  
end
