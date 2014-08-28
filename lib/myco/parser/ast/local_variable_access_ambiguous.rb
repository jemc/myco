
module CodeTools::AST
  
  module ProcessorMethods
    def process_lambig line, name
      LocalVariableAccessAmbiguous.new line, name
    end
  end
  
  class LocalVariableAccessAmbiguous < Node
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    def bytecode g
      pos(g)
      
      implementation(g).bytecode(g)
    end
    
    def to_sexp
      [:lambig, @name]
    end
    
    def implementation g
      if g.state.scope.variables.has_key? @name
        LocalVariableAccess.new @line, @name
      else
        rcvr = Self.new @line
        Send.new @line, rcvr, @name, true, true
      end
    end
  end
  
end
