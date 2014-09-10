
module CodeTools::AST
  
  module ProcessorMethods
    def process_declfile line, body
      DeclareFile.new line, body
    end
  end
  
  class DeclareFileScope < MycoModuleScope
    def body_bytecode g
      g.push_scope
      g.send :set_myco_file, 0
      g.pop
      
      @body.bytecode g
    end
  end
  
  class DeclareFile < Node
    attr_accessor :body
    
    # Use minimal inspect to avoid huge inspect output for inner AST nodes
    # that store a reference to a DeclareFile in an instance variable. 
    def inspect
      to_s
    end
    
    def initialize line, body
      @line = line
      @body = body
    end
    
    def to_sexp
      [:declfile, @body.to_sexp]
    end
    
    def implementation
      myco = ToplevelConstant.new @line, :Myco
      type = ScopedConstant.new @line, myco, :FileToplevel
      types = ArrayLiteral.new @line, [type]
      decl = DeclareObject.new @line, types, @body
      decl.scope_type = DeclareFileScope
      decl
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
  end
  
end
