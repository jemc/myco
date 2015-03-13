
module Myco
  module InstanceMethods
    include ::Kernel
    
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
    
    # TODO: remove (for now it makes debugging easier with RSpec)
    def pretty_print str
      p str
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
  end
  
  class Instance < ::BasicObject
    include InstanceMethods
    
    # # TODO: clean this up
    # prepend (::Module.new {
      def method_missing name, *args
        msg = "#{to_s} has no method called '#{name}'"
        ::Kernel.raise ::NoMethodError.new(msg, name, args)
      end
    # })
    
  end
end
