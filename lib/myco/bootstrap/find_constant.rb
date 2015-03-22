
# TODO: Move monkey patch to different file
module Rubinius
  class ConstantScope
    attr_reader :myco_file
    attr_reader :myco_component
    attr_reader :myco_category
    attr_reader :myco_meme
    
    # TODO: Can this be more graceful and more eager?
    def myco_file
      @myco_file ||= parent.myco_file
    end
    
    def myco_levels
      @myco_levels ||= (parent ? parent.myco_levels.dup : [])
    end
    
    def set_myco_file
      raise "myco_file already set for thie ConstantScope" \
        if @myco_file
      @myco_component = self.module
      @myco_file      = self.module
      
      @myco_file.instance_variable_set(:@constant_scope, self)
      
      myco_levels << @myco_file
    end
    
    def set_myco_component
      raise "myco_component already set for thie ConstantScope" \
        if @myco_component
      @myco_component = self.module
      @myco_file      = parent.myco_file
      
      myco_levels << @myco_component
    end
    
    def set_myco_category
      raise "myco_category already set for thie ConstantScope" \
        if @myco_category
      @myco_category  = self.module
      @myco_component = parent.myco_component
      @myco_file      = parent.myco_file
      
      myco_levels << @myco_category
    end
    
    def set_myco_meme value
      raise "myco_meme already set for thie ConstantScope" \
        if @myco_meme
      @myco_meme      = value
    end
  end
end

module Myco
  
  # Get the "current" ConstantScope (from the caller's perspective)
  def self.cscope
    Rubinius::ConstantScope.of_sender
  end
  
  def self.find_constant(name, scope=Rubinius::ConstantScope.of_sender)
    # TODO: optimize this constant search
    # (it currently searches each ancestor of each nested component scope)
    bucket = nil
    scope.myco_levels.detect { |level|
      bucket = find_constant_bucket_in_module(level, name)
    }
    bucket ? bucket.constant : Rubinius::Type.const_get(::Myco, name)
  end
  
  def self.find_constant_bucket_in_module(mod, name, inherit=true)
    current = mod
    
    while current and Rubinius::Type.object_kind_of? current, Module
      if bucket = current.constant_table.lookup(name)
        return bucket
      end
      
      return nil unless inherit
      
      current = current.direct_superclass
    end
    
    return nil
  end

end