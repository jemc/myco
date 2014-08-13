
module Myco
  class Instance < ::BasicObject
    include ::Kernel
    
    def to_s
      id = self.id || "0x#{component.object_id.to_s 16}"
      "#<Instance:#{id}>"
    end
    
    def inspect
      to_s
    end
    
    def initialize component
      @component = component
    end
    
    attr_reader :component
    
    def parent
      @component.parent && @component.parent.instance
    end
    
    def id
      @component.id
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
