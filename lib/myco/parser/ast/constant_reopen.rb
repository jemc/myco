
module CodeTools::AST
  
  module ProcessorMethods
    def process_copen line, name, body
      ConstantReopen.new line, name, body
    end
  end
  
  class ConstantReopenScope < ModuleScope
    def initialize(line, body)
      @line = line
      @name = :ConstantReopenScope # TODO: remove/fix
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
      attach_and_call g, :__component_init__, true
    end
  end
  
  class ConstantReopen < Node
    attr_accessor :name, :body
    
    def initialize line, name, body
      @line   = line
      @name   = name
      @body   = body
    end
    
    def to_sexp
      [:copen, @name.name, @body.to_sexp]
    end
    
    def bytecode g
      pos(g)
      
      scope = ConstantReopenScope.new @line, @body
      
      @name.bytecode g
      scope.bytecode g
    end
  end
  
end
