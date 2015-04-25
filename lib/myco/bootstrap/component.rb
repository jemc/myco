
module Myco
  module Component
    include MemeBindable
    
    attr_accessor :__last__
    attr_accessor :__name__
    
    attr_reader :parent
    attr_reader :parent_meme
    attr_reader :main
    
    attr_reader :constant_scope
    
    def to_s
      if defined?(::Myco::Category) && (self < ::Myco::Category)
        "#{parent.to_s}[#{@__name__}]"
      elsif @__name__
        @__name__.to_s
      else
        "#{(@super_components || []).map(&:to_s).join(',')}" \
          "(#{@basename}:#{@line.to_s} 0x#{object_id.to_s 16})"
      end
    end
    
    def method_missing(name, *args, &block)
      msg = "#{to_s} has no method called '#{name}'"
      ::Kernel.raise ::NoMethodError.new(msg, name, args)
    end
    
    def self.new super_components=[], parent=nil, filename=nil, line=nil
      locations = Rubinius::VM.backtrace(1,false)
      
      # Walk backwards on the backtrace until a lexical parent meme is found
      i = 0
      parent_meme = nil
      current = nil
      while true
        current = locations[i]
        break unless current
        parent_meme = current.constant_scope.myco_evctx.myco_meme
        break if parent_meme
        i += 1
      end
      @constant_scope = current.constant_scope if current
      
      # Get the filename and line from the VM if not specified
      if !filename || !line
        location = locations.first
        filename ||= location.file
        line     ||= location.line
      end
      
      this = Class.new Instance
      # TODO: avoid extending here to avoid touching/making the singleton_class
      this.extend self
      
      this.instance_eval {
        @super_components = super_components
        @parent      = parent
        @main        = self
        @filename    = filename
        @line        = line
        @basename    = File.basename @filename
        @dirname     = File.dirname  @filename
        @parent_meme = parent_meme
        @categories  = Rubinius::LookupTable.new
      }
      
      all_categories = Hash.new { |h,k| h[k] = Array.new }
      
      super_components.each do |other|
        this.include other
        
        if other.is_a? Component
          other.each_category do |name, cat|
            all_categories[name] << cat unless name == :main
          end
        end
      end
      
      all_categories.each do |name, supers|
        this.__new_category__(name, supers, filename, line)
      end
      
      this
    end
    
    def __get_category__ name
      if name == :main
        self
      elsif @categories.key?(name)
        @categories[name]
      else
        # If the category doesn't exist, look for one in the super components.
        # This allows for categories to be implicitly inherited after the fact.
        super_cats = []
        @super_components.each { |sup|
          sup.respond_to?(:__get_category__) && (
            cat = sup.__get_category__(name)
            cat && super_cats.push(cat)
          )
        }
        super_cats.any? && __new_category__(name, super_cats, @filename, @line)
      end
    end
    
    def __set_category__ name, cat
      @categories[name] = cat
      cat
    end
    
    def __new_category__ name, super_cats=[::Myco::Category], filename=nil, line=nil
      # Get the filename and line from the VM if not specified
      if !filename || !line
        location = Rubinius::VM.backtrace(2,false).first
        filename ||= location.file
        line     ||= location.line
      end
      
      category = Component.new super_cats, self, filename, line
      category.instance_variable_set(:@main, self)
      category.__name__ = name
      category_instance = category.instance
      meme = declare_meme(name) { category_instance }
      meme.cache = true
      
      __set_category__(name, category)
    end
    
    def __category__ name
      __get_category__(name) || __new_category__(name)
    end
    
    alias_method :category, :__category__
    
    def each_category &block
      @categories.each &block
    end
    
    def instance
      if @instance
        yield @instance if block_given?
      else
        @instance = allocate
        @instance.instance_variable_set(:@component, self)
        yield @instance if block_given?
        @instance.__signal__ :creation if Rubinius::Type.object_respond_to?(@instance, :__signal__)
      end
      
      @instance
    end
    
    # Override Module#include to bypass type checks of others
    def include *others
      others.reverse_each do |other|
        Rubinius::Type.include_modules_from(other, self.origin)
        # TODO: avoid touching singleton class that doesn't already exist?
        Rubinius::Type.include_modules_from(other.singleton_class, self.singleton_class.origin)
        Rubinius::Type.infect(self, other)
        other.__send__ :included, self
      end
      self
    end
    
    # Use instead of other's Module#include to bypass type checks
    def include_into other
      Rubinius::Type.include_modules_from(self, other.origin)
      Rubinius::Type.infect(other, self)
      other.__send__ :included, self
    end
    
    # Extend the given object with this component's features
    # Called on object.extend(component)
    def extend_object object
      singleton_class = Rubinius::Type.object_singleton_class(object)
      Rubinius::Type.include_modules_from(self, singleton_class.origin)
      Rubinius::Type.infect(singleton_class, self)
      object
    end
    
    # Create a child component of self to act as the component of the object,
    # which is allowed to be a Ruby object (not a Myco::Instance).
    # TODO: re-evaluate usefulness and possibly remove in favor of using extend.
    def inject_into object
      object.extend InstanceMethods unless object.is_a? InstanceMethods
      object.instance_variable_set(:@component, self)
      extend_object object
      object
    end
    
    # Create an untracked instance of this component and
    # call setters on the instance with the values given by kwargs.
    def new **kwargs
      instance = allocate
      instance.instance_variable_set(:@component, self)
      kwargs.each { |key,val| instance.__send__ :"#{key}=", val }
      instance
    end
  end
  
  # TODO: use a better approach than this monkey-patch
  class ::Module
    include ::Myco::MemeBindable
    
    # Like module_eval, but it also shifts the ConstantScope of the block
    def component_eval &block
      block_env = block.block
      cscope = Rubinius::ConstantScope.new(self, block_env.constant_scope)
      if defined? ::Myco::FileToplevel && self < ::Myco::FileToplevel
        cscope.myco_evctx.set_myco_file
      elsif defined? ::Myco::Category && self < ::Myco::Category
        cscope.myco_evctx.set_myco_category
      else
        cscope.myco_evctx.set_myco_component
      end
      result = block_env.call_under(self, cscope, true, self)
      result
    end
  end
  
end
