
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
        parent = scope.myco_evctx.myco_parent
        parent ? parent.get_myco_constant_ref(name).value : (
          Rubinius::Type.const_get(::Myco, name)
        )
      )
    end
    
    def find_constant_bucket_in_module mod, name
      current = mod
      while current and Rubinius::Type.object_kind_of? current, Module
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
  
  # TODO: accept evctx instead of scope as argument
  def self.find_constant(name, scope=Rubinius::ConstantScope.of_sender)
    scope.myco_evctx.get_myco_constant_ref(name).value
  end
end
