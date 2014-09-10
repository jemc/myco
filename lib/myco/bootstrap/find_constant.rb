
# TODO: Move monkey patch to different file
module Rubinius
  class ConstantScope
    attr_reader :myco_file
    attr_reader :myco_component
    attr_reader :myco_category
    
    def set_myco_file
      @myco_component = self.module
      @myco_file      = self.module
    end
    
    def set_myco_component
      @myco_component = self.module
      @myco_file      = parent.myco_file
    end
    
    def set_myco_category
      @myco_category  = self.module
      @myco_component = parent.myco_component
      @myco_file      = parent.myco_file
    end
  end
end

module Myco
  
  def self.find_constant(name, scope)
    name = ::Rubinius::Type.coerce_to_constant_name name
    
    category  = scope.myco_category
    component = scope.myco_component
    file      = scope.myco_file
    
    (category    && find_constant_in_module(category, name))    ||
      (component && find_constant_in_module(component, name)) ||
        (file    && find_constant_in_module(file, name))    ||
          ::Rubinius::Type.const_get(::Myco, name)
  end
  
  def self.find_constant_in_module(mod, name, inherit=true)
    current, constant = mod, nil
    
    while current and ::Rubinius::Type.object_kind_of? current, Module
      if bucket = current.constant_table.lookup(name)
        return bucket.constant
      end
      
      return nil unless inherit
      
      current = current.direct_superclass
    end
  end

end