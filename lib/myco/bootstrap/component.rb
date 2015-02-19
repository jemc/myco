
module Myco
  module Component
    include MemeBindable
    
    attr_accessor :__last__
    attr_accessor :__name__
    
    attr_reader :parent
    attr_reader :parent_meme
    attr_reader :categories
    
    attr_reader :constant_scope
    
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
      locations = Rubinius::VM.backtrace(1,false)
      
      # Walk backwards on the backtrace until a lexical parent meme is found
      i = 0
      parent_meme = nil
      current = nil
      while true
        current = locations[i]
        break unless current
        parent_meme = current.constant_scope.myco_meme
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
        @filename    = filename
        @line        = line
        @basename    = File.basename @filename
        @dirname     = File.dirname  @filename
        @categories  = { main: this }
        @parent_meme = parent_meme
      }
      
      all_categories = Hash.new { |h,k| h[k] = Array.new }
      
      super_components.each do |other|
        raise TypeError, "Got non-Component in supers for new Component: "\
          "#{super_components.inspect}" \
              unless other.is_a? Component
        
        this.include other
        other.categories.each do |name, cat|
          all_categories[name] << cat
        end
      end
      
      all_categories.each do |name, supers|
        if name == :main
          this.categories[name] = this
        else
          this.categories[name] = this.__new_category__ name, supers, filename, line
        end
      end
      
      this
    end
    
    # Get a reference to the main Component from main or from any inner Category
    def main
      self < Category ? parent : self
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
      meme = declare_meme(name) { category_instance }
      meme.cache = true
      
      category
    end
    
    def instance
      if @instance
        yield @instance if block_given?
      else
        @instance = allocate
        @instance.instance_variable_set(:@component, self)
        yield @instance if block_given?
        @instance.__signal__ :creation if @instance.respond_to? :__signal__
      end
      
      @instance
    end
    
    # Override Module#include to bypass type checks of others
    def include *others
      others.reverse_each do |other|
        Rubinius::Type.include_modules_from(other, self.origin)
        Rubinius::Type.infect(self, other)
        other.__send__ :included, self
      end
      self
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
      kwargs.each { |key,val| instance.send :"#{key}=", val }
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
        cscope.set_myco_file
      elsif defined? ::Myco::Category && self < ::Myco::Category
        cscope.set_myco_category
      else
        cscope.set_myco_component
      end
      result = block_env.call_under(self, cscope, true, self)
      result
    end
  end
  
end
