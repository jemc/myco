
module Myco
  module InstanceMethods
    attr_reader :component
    
    def parent
      @component.parent && @component.parent.instance
    end
    
    def parent_meme
      @component.parent_meme
    end
    
    def memes
      @component.memes
    end
  end
  
  Instance = Class.new nil do
    include ::Kernel
    include InstanceMethods
    
    # These are not included in InstanceMethods because they should not shadow
    # existing method definitions when extended into an existing object. 
    
    def method_missing name, *args
      msg = "#{to_s} has no method called '#{name}'"
      ::Kernel.raise ::NoMethodError.new(msg, name, args)
    end
    
    def to_s
      "#<#{@component.to_s}>"
    end
    
    def inspect
      vars = (instance_variables - [:@component]).map { |var|
        [var.to_s[1..-1], instance_variable_get(var).inspect].join(": ")
      }
      vars = vars.any? ? (" " + vars.join(", ")) : ""
      "#<#{@component.to_s}#{vars}>"
    end
    
    # These methods are taken from Ruby's BasicObject.
    # TODO: Audit which of these should remain.
    
    def __send__ message, *args
      Rubinius.primitive :object_send
      raise ::PrimitiveFailure, "Rubinius.primitive :object_send failed"
    end

    def __id__
      Rubinius.primitive :object_id
      raise ::PrimitiveFailure, "Rubinius.primitive :object_id failed"
    end
    
    def __all_instance_variables__
      Rubinius.primitive :object_ivar_names
      raise ::PrimitiveFailure, "Rubinius.primitive :object_ivar_names failed"
    end
    
    def equal?(other)
      Rubinius.primitive :object_equal
      raise ::PrimitiveFailure, "Rubinius.primitive :object_equal failed"
    end
    
    alias_method :==, :equal?
    
    def !
      Rubinius::Type.object_equal(self, false) ||
        Rubinius::Type.object_equal(self, nil) ? true : false
    end
    
    def !=(other)
      self == other ? false : true
    end
  end
  
end
