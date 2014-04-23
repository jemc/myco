
module Myco::ToolSet::AST
  
  class DeclareObject < Node
    attr_accessor :types
    
    def initialize line, types
      @line  = line
      @types = types
    end
    
    def to_sexp
      [:declobj, @types.to_sexp]
    end
    
    def implementation
      const = ConstantAccess.new @line, :Component
      SendWithArguments.new @line, const, :new, @types
    end
    
    def bytecode g
      implementation.bytecode g
    end
  end
  
  class DeclareString < Node
    attr_accessor :types
    attr_accessor :string
    
    def initialize line, types, string
      @line   = line
      @types  = types
      @string = string
    end
    
    def to_sexp
      [:declstr, @types.to_sexp, @string.to_sexp]
    end
    
    def implementation
      const = ConstantAccess.new @line, :Component
      comp  = SendWithArguments.new @line, const, :new, @types
      args  = ArrayLiteral.new @string.line, [@string]
      SendWithArguments.new @string.line, comp, :from_string, args
    end
    
    def bytecode g
      implementation.bytecode g
    end
  end
  
end


module Myco::ToolSet
  class Parser
    
    ##
    # AST building methods
    # (supplementing those inherited from rubinius/processor)
    
    def process_declobj line, types
      AST::DeclareObject.new line, types
    end
    
    def process_declstr line, types, string
      AST::DeclareString.new line, types, string
    end
    
  end
end
