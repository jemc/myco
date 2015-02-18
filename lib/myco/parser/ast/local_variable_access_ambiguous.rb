
module CodeTools::AST
  
  module BuilderMethods
    def lambig loc, name
      LocalVariableAccessAmbiguous.new loc.line, name
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
      
      local = g.state.scope.search_local @name
      return local.get_bytecode(g) if local
      
      rcvr = Self.new @line
      send = Send.new @line, rcvr, @name, true, true
      send.bytecode(g)
    end
    
    def to_sexp
      [:lambig, @name]
    end
  end
  
end
