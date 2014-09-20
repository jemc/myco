
module CodeTools::AST
  
  module ProcessorMethods
    def process_meme line, name, decorations, arguments, body
      DeclareMeme.new line, name, decorations, arguments, body
    end
  end
  
  class DeclareMemeBody < Iter
  end
  
  class DeclareMeme < Node
    attr_accessor :name, :decorations, :arguments, :body
    
    def initialize line, name, decorations, arguments, body
      @line        = line
      @name        = name.value
      @decorations = decorations || ArrayLiteral.new(line, [])
      @arguments   = arguments || Parameters.new(line, [], nil, false, nil, nil, nil, nil)
      @body        = body || NilLiteral.new(line)
    end
    
    def to_sexp
      [:meme, @name, @decorations.to_sexp, @arguments.to_sexp, @body.to_sexp]
    end
    
    def bytecode(g)
      pos(g)
      
      meme_body = DeclareMemeBody.new(@line, @arguments, @body)
      
      ##
      # module = scope.for_method_definition
      # module.send :declare_meme, @name, @decorations,
      #   CompiledCode(@body), const_scope, var_scope
      #
      g.push_scope
      g.send :for_method_definition, 0
        g.push_literal @name
        @decorations.bytecode g
        meme_body.bytecode(g)
        g.push_scope
        g.push_variables
      g.send :declare_meme, 5
    end
  end
  
end
