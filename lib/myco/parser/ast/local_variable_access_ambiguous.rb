
module CodeTools::AST
  
  module ProcessorMethods
    def process_lambig line, name
      LocalVariableAccessAmbiguous.new line, name
    end
  end
  
  class LocalVariableAccessAmbiguous < Node
    attr_accessor :name
    attr_accessor :declfile
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    # TODO: fix/replace CodeTools::AST::AsciiGrapher to not infinitely recurse
    def instance_variables
      super - [:@declfile]
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
      elsif @declfile && @declfile.seen_ids.include?(@name)
        AccessById.new @line, @name
      else
        rcvr = Self.new @line
        Send.new @line, rcvr, @name, true, true
      end
    end
  end
  
end
