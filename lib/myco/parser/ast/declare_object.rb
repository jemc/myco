
module CodeTools::AST
  
  module ProcessorMethods
    def process_declobj line, types, body
      DeclareObject.new line, types, body
    end
  end
  
  class DeclareObjectScope < ModuleScope
    def initialize(line, body)
      @line = line
      @name = :DeclareObjectScope # TODO: remove/fix
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
      attach_and_call g, :__component_init__, true
    end
  end
  
  class DeclareObject < Node
    attr_accessor :types, :body
    attr_accessor :create
    
    def initialize line, types, body
      @line   = line
      @types  = types
      @body   = body
      @create = true
    end
    
    def to_sexp
      [:declobj, @types.to_sexp, @body.to_sexp]
    end
    
    def bytecode g
      pos(g)
      
      scope = DeclareObjectScope.new @line, @body
      
      # Component.new types, parent, filename
      ConstantAccess.new(@line, :Component).bytecode g
        @types.bytecode g
        g.push_scope; g.send :for_method_definition, 0
        g.push_scope; g.send :active_path, 0; g.meta_to_s
      g.send :new, 3
      
      # The return value of Component.new at the top of the stack
      # will be consumed by @scope.bytecode, so save two copies of it.
      g.dup_top # One for sending :__last__= to
      g.dup_top # One for sending :instance to (or returning, if !@create)
      
      # Compile the inner scope,
      # leaving the last object in the scope at the top of the stack.
      scope.bytecode g
      
      # component.__last__ = (value left on stack from @scope.bytecode)
      g.send :__last__=, 1
      g.pop
      
      # return (@create ? component.instance : component)
      g.send :instance, 0 if @create
    end
  end
  
end
