
# TODO: Move monkey patch to different file
module Rubinius
  class ConstantScope
    attr_reader :myco_file
    attr_reader :myco_component
    attr_reader :myco_category
    attr_reader :myco_meme
    attr_reader :is_myco_level
    
    def inspect_list
      this_item = "0x#{object_id.to_s(16)} #{self.module}"
      parent ? "#{this_item}, #{parent.inspect_list}" : this_item
    end
    
    def inspect
      "#<#{self.class}:#{inspect_list}>"
    end
    
    # TODO: Can this be more graceful and more eager?
    def myco_file
      @myco_file ||= parent.myco_file
    end
    
    def myco_levels
      @myco_levels ||= (parent ? parent.myco_levels.dup : [])
    end
    
    def myco_parent
      parent = parent()
      parent ? (
        parent.is_myco_level ? parent : parent.myco_parent
      ) : nil
    end
    
    def set_myco_file
      raise "myco_file already set for thie ConstantScope" \
        if @myco_file
      @myco_component = self.module
      @myco_file      = self.module
      
      @myco_file.instance_variable_set(:@constant_scope, self)
      
      myco_levels << @myco_file
      @is_myco_level = true
    end
    
    def set_myco_component
      raise "myco_component already set for thie ConstantScope" \
        if @myco_component
      @myco_component = self.module
      @myco_file      = parent.myco_file
      
      myco_levels << @myco_component
      @is_myco_level = true
    end
    
    def set_myco_category
      raise "myco_category already set for thie ConstantScope" \
        if @myco_category
      @myco_category  = self.module
      @myco_component = parent.myco_component
      @myco_file      = parent.myco_file
      
      myco_levels << @myco_category
      @is_myco_level = true
    end
    
    def set_myco_meme value
      raise "myco_meme already set for thie ConstantScope" \
        if @myco_meme
      @myco_meme      = value
    end
    
    def get_myco_constant_ref(name)
      @myco_constant_refs ||= Rubinius::LookupTable.new
      @myco_constant_refs[name] ||= ::Myco::ConstantReference.new(name, self)
    end
  end
end

module Myco
  class ConstantReference
    class << self
      attr_accessor :verbose
    end
    
    attr_reader :name
    attr_reader :scope
    
    def initialize name, scope
      @name  = name
      @scope = scope
    end
    
    def value
      serial = @serial
      new_serial = Rubinius.global_serial
      
      if serial && serial >= new_serial
        @value
      else
        @serial = new_serial
        @value = find_value
      end
    end
    
    def find_value
      bucket = find_constant_bucket_in_module(scope.module, name)
      bucket ? bucket.constant : (
        parent = scope.myco_parent
        parent ? parent.get_myco_constant_ref(name).value : (
          Rubinius::Type.const_get(::Myco, name)
        )
      )
    end
    
    def find_constant_bucket_in_module mod, name
      current = mod
      while current and Rubinius::Type.object_kind_of? current, Module
        # p current if Myco::ConstantReference.verbose
        return bucket if bucket = current.constant_table.lookup(name)
        current = current.direct_superclass
      end
      
      return nil
    end
  end
  
  # Get the "current" ConstantScope (from the caller's perspective)
  def self.cscope
    Rubinius::ConstantScope.of_sender
  end
  
  def self.find_constant(name, scope=Rubinius::ConstantScope.of_sender)
    scope.get_myco_constant_ref(name).value
  end
end
