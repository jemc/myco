
module Myco
  module InstanceMethods
    include ::Kernel
    
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
