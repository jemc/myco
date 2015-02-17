
module CodeTools::AST
  
  module BuilderMethods
    def declstr line, types, string
      DeclareString.new line, types, string
    end
  end
  
  class DeclareString < Node
    attr_accessor :types, :string
    
    def initialize line, types, string
      @line   = line
      @types  = types
      @string = string
    end
    
    def to_sexp
      [:declstr, @types.to_sexp, @string.to_sexp]
    end
    
    def implementation
      blk   = NilLiteral.new @line
      obj   = DeclareObject.new @line, @types, blk
      args  = ArgumentAssembly.new @string.line, [@string]
      InvokeMethod.new @string.line, obj, :from_string, args
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
  end
  
end
