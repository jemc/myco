
module CodeTools::AST
  
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
    
    def implementation
      # comp = Component.new(@types, &@body)
      # obj  = (@create ? comp.new : comp)
      # return obj
      
      const = ConstantAccess.new @line, :Component
      itera = Parameters.new line, nil, nil, nil, nil, nil, nil, nil
      iter  = Iter.new @line, itera, @body
      args  = ArrayLiteral.new @types.line, [@types]
      comp  = SendWithArguments.new @line, const, :new, args
      comp.instance_variable_set :@block, iter
      @create ? Send.new(@line, comp, :new) : comp
    end
    
    def bytecode g
      implementation.bytecode g
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
      implementation.bytecode g
    end
  end
  
  class DeclareBinding < Node
    attr_accessor :name, :decorations, :args, :body
    
    def initialize line, name, decorations, args, body
      @line        = line
      @name        = name
      @decorations = decorations || ArrayLiteral.new(line, [])
      @args        = args
      @body        = body
    end
    
    def to_sexp
      [:bind, @name.value, @decorations.to_sexp, @args.to_sexp, @body.to_sexp]
    end
    
    def implementation
      # Binding.new(self, @name, @decorations, &@body)
      
      const = ConstantAccess.new @line, :Binding
      rcvr  = Self.new @line
      bargs = ArrayLiteral.new @line, [rcvr, @name, @decorations]
      iter  = Iter.new @line, @args, @body
      bind  = SendWithArguments.new @line, const, :new, bargs
      bind.instance_variable_set :@block, iter
      bind
    end
    
    def bytecode g
      implementation.bytecode g
    end
  end
  
  class DeclareCategory < Node
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    def to_sexp
      [:category, @name]
    end
    
    def implementation
      # Category.new(self, @name).embed
      
      const = ConstantAccess.new @line, :Category
      rcvr  = Self.new @line
      cargs = ArrayLiteral.new @line, [rcvr, @name]
      categ = SendWithArguments.new @line, const, :new, cargs
      Send.new @line, categ, :embed
    end
    
    def bytecode g
      implementation.bytecode g
    end
  end
  
  class LocalVariableAccessAmbiguous < Node
    attr_accessor :name
    
    def initialize line, name
      @line = line
      @name = name
    end
    
    def bytecode g
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
    
    def process_bind line, name, decorations, args, body
      DeclareBinding.new line, name, decorations, args, body
    end
    
    def process_category line, name
      DeclareCategory.new line, name
    end
    
    def process_lambig line, name
      LocalVariableAccessAmbiguous.new line, name
    end
  end
end
