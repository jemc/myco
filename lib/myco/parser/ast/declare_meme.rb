
module CodeTools::AST
  
  module ProcessorMethods
    def process_meme line, name, decorations, arguments, body
      DeclareMeme.new line, name, decorations, arguments, body
    end
  end
  
  class DeclareMemeBody < Iter
    attr_accessor :name
    
    def bytecode(g)
      pos(g)
      
      g.state.scope.nest_scope self
      
      meth = new_generator g, @name, @arguments
      
      meth.push_state self
      meth.state.push_super self
      meth.definition_line @line
      
      meth.state.push_name @name
      
      @arguments.bytecode meth
      @body.bytecode meth
      
      meth.state.pop_name
      
      meth.local_count = local_count
      meth.local_names = local_names
      meth.splat_index = @arguments.splat_index
      
      meth.ret
      meth.close
      meth.pop_state
      
      g.push_scope
      g.send :for_method_definition, 0
      g.add_scope
      
      # Create the BlockEnvironment from the meth Generator
      g.create_block meth
    end
  end
  
  class DeclareMeme < Node
    attr_accessor :name, :decorations, :arguments, :body
    
    def initialize line, name, decorations, arguments, body
      @line        = line
      @name        = name.value
      @decorations = decorations || ArrayAssembly.new(line, [])
      @arguments   = arguments || Parameters.new(line, [], nil, true, nil, nil, nil, nil)
      @body        = body || NilLiteral.new(line)
    end
    
    def to_sexp
      [:meme, @name, @decorations.to_sexp, @arguments.to_sexp, @body.to_sexp]
    end
    
    def body_implementation
      meme_body = DeclareMemeBody.new(@line, @arguments, @body)
      meme_body.name = @name
      meme_body
    end
    
    def bytecode(g)
      pos(g)
      
      ##
      # module = scope.for_method_definition
      # module.send :declare_meme, @name, @decorations,
      #   BlockEnvironment(body_implementation)
      #
      g.push_scope
      g.send :for_method_definition, 0
        g.push_literal @name
        @decorations.bytecode g
        body_implementation.bytecode(g)
      g.send :declare_meme, 3
    end
  end
  
end
