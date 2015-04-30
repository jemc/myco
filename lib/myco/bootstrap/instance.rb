
# This is a workaround because Rubinius doesn't expose Class::set_type_info(),
# so we cannot simply assign the type_info for our new class to TupleType.
# So, we dup a class for its type_info, then clear all methods and ancestors.
Myco::PrimitiveTuple = Rubinius::Tuple.dup
Myco::PrimitiveTuple.instance_eval do
  set_superclass(nil)
  
  instance_methods.each do |name|
    method_table.delete(name)
    Rubinius::VM.reset_method_cache(self, name)
  end
  
  methods(false).each do |name|
    singleton_class.method_table.delete(name)
    Rubinius::VM.reset_method_cache(singleton_class, name)
  end
end

module Myco
  module PrimitiveInstanceMethods
    def __tuple_at__ idx
      Rubinius.primitive :tuple_at
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :tuple_at failed"
    end
    
    def __tuple_put__ idx, val
      Rubinius.primitive :tuple_put
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :tuple_put failed"
    end
    
    # These methods are taken from Ruby's Kernel.
    # TODO: Audit which of these should remain.
    
    def __set_ivar__ sym, value
      Rubinius.primitive :object_set_ivar
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_set_ivar failed"
    end
    
    def __get_ivar__ sym
      Rubinius.primitive :object_get_ivar
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_get_ivar failed"
    end
    
    def __ivar_defined__ sym
      Rubinius.primitive :object_ivar_defined
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_ivar_defined failed"
    end
    
    def __kind_of__ mod
      Rubinius.primitive :object_kind_of
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_kind_of failed"
    end
    
    def __class__
      Rubinius.primitive :object_class
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_class failed"
    end
    
    def __dup__ # TODO: remove
      copy = Rubinius::Type.object_class(self).allocate
      Rubinius.invoke_primitive :object_copy_object, copy, self
      copy
    end
    
    def __hash__
      Rubinius.primitive :object_hash
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_hash failed"
    end
    
    # These methods are taken from Ruby's BasicObject.
    # TODO: Audit which of these should remain.
    
    def __send__ message, *args
      Rubinius.primitive :object_send
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_send failed"
    end

    def __id__
      Rubinius.primitive :object_id
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_id failed"
    end
    
    def __ivar_names__
      Rubinius.primitive :object_ivar_names
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_ivar_names failed"
    end
    
    def __equal__(other)
      Rubinius.primitive :object_equal
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :object_equal failed"
    end
  end
  
  module InstanceMethods
    include PrimitiveInstanceMethods
    
    def component
      __component__
    end
    
    def parent
      __component__.parent && __component__.parent.instance
    end
    
    def parent_meme
      __component__.parent_meme
    end
    
    def memes
      __component__.memes
    end
  end
  
  Instance = Class.new Myco::PrimitiveTuple do
    include InstanceMethods
    
    def self.__tuple_size__
      0
    end
    
    def self.__tuple_allocate__ size
      Rubinius.primitive :tuple_allocate
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :tuple_allocate failed"
    end
    
    def self.__tuple_pattern__ size
      Rubinius.primitive :tuple_pattern
      ::Kernel.raise ::PrimitiveFailure, "Rubinius.primitive :tuple_pattern failed"
    end
    
    def self.allocate
      Rubinius::Unsafe.set_class(__tuple_pattern__(__tuple_size__, Myco.undefined), self)
    end
    
    # These are not included in InstanceMethods because they should not shadow
    # existing method definitions when extended into an existing object. 
    
    def method_missing name, *args
      msg = "#{to_s} has no method called '#{name}'"
      ::Kernel.raise ::NoMethodError.new(msg, name, args)
    end
    
    def to_s
      "#<#{__component__.to_s}>"
    end
    
    def inspect
      vars = __ivar_names__.map { |var|
        [var.to_s[1..-1], __get_ivar__(var).inspect].join(": ")
      }
      vars = vars.any? ? (" " + vars.join(", ")) : ""
      "#<#{__component__.to_s}#{vars}>"
    end
    
    alias_method :hash,   :__hash__   # TODO: remove?
    alias_method :equal?, :__equal__  # TODO: remove?
    alias_method :==,     :__equal__  # TODO: remove?
    
    def != other
      self == other ? false : true
    end
    
    alias_method :"!", :false?
  end
  
end
