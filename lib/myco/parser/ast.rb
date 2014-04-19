
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
end
