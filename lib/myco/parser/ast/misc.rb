
module CodeTools::AST
  
  module ProcessorMethods
    def process_null line
      NullLiteral.new line
    end
    
    def process_void line
      VoidLiteral.new line
    end
  end
  
  class NullLiteral < NilLiteral
    def to_sexp
      [:null]
    end
  end
  
  # Replace NilLiteral with NullLiteral and let original NilLiteral "disappear"
  NilLiteral = NullLiteral
  
  class VoidLiteral < Node
    def bytecode(g)
      pos(g)
      
      # TODO: create push_void helper to abstract this out (and elsewhere)
      g.push_cpath_top
      g.find_const :Myco
      g.find_const :Void
    end
    
    def to_sexp
      [:void]
    end
  end
  
end
