
module Myco
  module InstanceMethods
  end
  
  class Instance < ::BasicObject
    include InstanceMethods
  end
  
  module InstanceMethods
    include ::Kernel
    
    # TODO: clean this up
    prepend (::Module.new {
      def method_missing name, *args
        msg = "#{to_s} has no method called '#{name}'"
        ::Kernel.raise ::NoMethodError.new(msg, name, args)
      end
    })
    
    def to_s
      "#<#{@component.to_s}>"
    end
    
    def inspect
      to_s
    end
    
    # TODO: remove (for now it makes debugging easier with RSpec)
    def pretty_print str
      p str
    end
    
    def initialize component
      @component = component
    end
    
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
    
    # Commandeer a few methods implemented in Kernel
    %i{ extend respond_to? method_missing hash }.each do |sym|
      define_method sym do |*args, &blk|
        ::Kernel.instance_method(sym).bind(self).call(*args)
      end
    end
  end
end
