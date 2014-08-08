
module Myco
  class Instance < ::BasicObject
    include ::Kernel
    
    def to_s
      "#<Instance(#{component})>"
    end
    
    def inspect
      to_s
    end
    
    attr_reader :component
    
    def initialize component
      @component = component
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
