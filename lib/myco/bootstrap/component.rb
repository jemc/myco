
module Myco
  class Component < Module
    attr_accessor :__last__
    attr_accessor :__name__
    
    attr_reader :parent
    attr_reader :memes
    attr_reader :categories
    
    def to_s
      if defined?(::Myco::Category) && (self < ::Myco::Category)
        "#{parent.to_s}[#{@__name__}]"
      elsif @__name__
        @__name__.to_s
      else
        "#{@super_components.map(&:to_s).join(',')}" \
          "(#{@basename}:#{@line.to_s} 0x#{object_id.to_s 16})"
      end
    end
    
    def self.new super_components=[], parent=nil, filename=nil, line=nil
      # Get the filename and line from the VM if not specified
      if !filename || !line
        location = Rubinius::VM.backtrace(1,false).first
        filename ||= location.file
        line     ||= location.line
      end
      
      this = super()
      
      this.instance_eval {
        @super_components = super_components
        @memes      = { }
        @parent     = parent
        @filename   = filename
        @line       = line
        @basename   = File.basename @filename
        @dirname    = File.dirname  @filename
        @categories = { nil => this }
      }
      
      all_categories = Hash.new { |h,k| h[k] = Array.new }
      
      super_components.each do |other|
        this.include other if other
        other.categories.each { |name, cat| all_categories[name] << cat }
      end
      
      all_categories.each do |name, supers|
        if name.nil?
          this.categories[name] = this
        else
          this.categories[name] = this.__new_category__ name, supers, filename, line
        end
      end
      
      this
    end
    
    def __category__ name
      @categories[name] ||= __new_category__(name)
    end
    
    def __new_category__ name, super_cats=[Category], filename=nil, line=nil
      # Get the filename and line from the VM if not specified
      if !filename || !line
        location = Rubinius::VM.backtrace(2,false).first
        filename ||= location.file
        line     ||= location.line
      end
      
      category = Component.new super_cats, self, filename, line
      category.__name__ = name
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
      loc = Rubinius::VM.backtrace(1,false).first
      
      Component.new([self], parent, loc.file, loc.line).instance { |instance|
        kwargs.each { |key,val| instance.send :"#{key}=", val }
      }
    end
    
    def const_get(name, inherit=true)
      ::Myco.const_get self, name, inherit
    end
  end
  
end
