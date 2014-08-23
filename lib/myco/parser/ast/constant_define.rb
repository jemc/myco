
module CodeTools::AST
  
  module ProcessorMethods
    def process_cdefn line, name, object
      ConstantDefine.new line, name, object
    end
  end
  
  class ConstantDefine < Node
    attr_accessor :name, :object
    
    def initialize line, name, object
      @line   = line
      @name   = name
      @object = object
      @object.create = false
    end
    
    def to_sexp
      [:cdefn, @name.name, @object.to_sexp]
    end
    
    def implementation
      ConstantAssignment.new @line, @name, @object
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
  end
  
end
