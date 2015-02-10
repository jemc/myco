
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
  
  class ::CodeTools::Generator
    def push_void
      push_cpath_top
      find_const :Myco
      find_const :Void
    end
  end
  
  class VoidLiteral < Node
    def bytecode(g)
      pos(g)
      g.push_void
    end
    
    def to_sexp
      [:void]
    end
  end
  
end
