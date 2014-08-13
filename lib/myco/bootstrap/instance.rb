
module Myco
  class Instance < ::BasicObject
    include ::Kernel
    
    def to_s
      @component.to_s.sub 'Component', 'Instance'
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
    
    def id_scope
      @component.id_scope
    end
    
    def get_by_id id
      @component.get_by_id id
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
