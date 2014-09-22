
require_relative 'myco_module_scope'


module CodeTools::AST
  
  module ProcessorMethods
    def process_copen line, name, body
      ConstantReopen.new line, name, body
    end
  end
  
  class ConstantReopenScope < MycoModuleScope
    def body_bytecode g
      g.push_scope
      g.send :set_myco_component, 0
      g.pop
      
      @body.bytecode g
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
