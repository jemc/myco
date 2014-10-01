
module CodeTools::AST
  
  module ProcessorMethods
    def process_deco line, name, arguments
      DeclareDecorator.new line, name, arguments
    end
  end
  
  class DeclareDecorator < Node
    attr_accessor :line, :name, :arguments
    
    def initialize line, name, arguments
      @line      = line
      @name      = name
      @arguments = arguments || ArrayAssembly.new(@line, [])
    end
    
    def to_sexp
      args_sexp = @arguments.to_sexp
      args_sexp[0] = :arglist
      sexp = [:deco, @name.value]
      sexp.push args_sexp unless @arguments.body.empty?
      sexp
    end
    
    def bytecode g
      pos(g)
      
      ary = ArrayLiteral.new @line, [@name, @arguments]
      ary.bytecode g
    end
  end
  
end
