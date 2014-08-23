
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
  
  
  # Patch the And (and Or) Node bytecode to use .false? to determine falsehood
  # This accomodates treating Void (or any other non-builtin) as falsey
  # TODO: use new branch instruction when it gets added to Rubinius
  class And
    def bytecode(g, use_git=true)
      @left.bytecode(g)
      g.dup
      lbl = g.new_label
      
      g.send :false?, 0
      if use_git
        g.git lbl
      else
        g.gif lbl
      end
      
      g.pop
      @right.bytecode(g)
      lbl.set!
    end
  end
  
end
