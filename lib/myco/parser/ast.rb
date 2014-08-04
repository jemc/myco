
module CodeTools::AST
  
  class DeclareObject < Node
    attr_accessor :types, :body
    attr_accessor :create
    
    def initialize line, types, body
      @line   = line
      @types  = types
      @body   = body
      @create = true
      @scope  = DeclareObjectScope.new @line, @body
    end
    
    def to_sexp
      [:declobj, @types.to_sexp, @body.to_sexp]
    end
    
    def bytecode g
      pos(g)
      
      ##
      # Component.new types, scope
      #
      ConstantAccess.new(@line, :Component).bytecode g
        @types.bytecode g
        g.push_scope
      g.send :new, 2
      
      # The return value of Component.new at the top of the stack
      # will be consumed by @body.bytecode, so save a copy of it.
      g.dup_top
      
      # Compile the inner scope
      @scope.bytecode g
      
      # Pop the return value of @body.bytecode,
      # so that the earlier duped value is the item left on the stack.
      g.pop
      
      # If @create is set, return the Component's
      # instance instead of the Component itself.
      g.send :instance, 0 if @create
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
      args  = ArrayLiteral.new @string.line, [@string]
      SendWithArguments.new @string.line, obj, :from_string, args
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
  end
  
  class ConstantDefine < Node
    attr_accessor :name, :object
    
    def initialize line, name, object
      @line   = line
      @name   = name
      @object = object
      @object.create = false
    end
    
    def to_sexp
      [:cdefn, @name.name, @object.to_sexp]
    end
    
    def implementation
      ConstantAssignment.new @line, @name, @object
    end
    
    def bytecode g
      pos(g)
      
      implementation.bytecode g
    end
  end
  
  class DefineMeme < Define
    attr_accessor :name, :decorations, :args, :body
    
    def initialize line, name, decorations, args, body
      @line        = line
      @name        = name.value
      @decorations = decorations || ArrayLiteral.new(line, [])
      @arguments   = args
      @body        = body
    end
    
    def to_sexp
      [:meme, @name, @decorations.to_sexp, @arguments.to_sexp, @body.to_sexp]
    end
    
    def bytecode(g)
      pos(g)
      
      ##
      # module = scope.for_method_definition
      # module.send :__meme__, @name, @decorations,
      #   CompiledCode(@body), const_scope, var_scope
      #
      g.push_scope
      g.send :for_method_definition, 0
        g.push_literal @name
        @decorations.bytecode g
        g.push_generator compile_body(g)
        g.push_scope
        g.push_variables
      g.send :__meme__, 5
    end
  end
  
  class DeclareCategory < Node
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name.value
    end
    
    def to_sexp
      [:category, @name]
    end
    
    def bytecode g
      pos(g)
      
      ##
      # self.__category__ @name
      #
      g.push_self
        g.push_literal @name
      g.send :__category__, 1
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
  
  module ProcessorMethods
    ##
    # AST building methods
    # (supplementing those inherited from rubinius/processor)
    
    def process_declobj line, types, body
      DeclareObject.new line, types, body
    end
    
    def process_declstr line, types, string
      DeclareString.new line, types, string
    end
    
    def process_cdefn line, name, object
      ConstantDefine.new line, name, object
    end
    
    def process_meme line, name, decorations, args, body
      DefineMeme.new line, name, decorations, args, body
    end
    
    def process_category line, name
      DeclareCategory.new line, name
    end
    
    def process_lambig line, name
      LocalVariableAccessAmbiguous.new line, name
    end
  end
end
