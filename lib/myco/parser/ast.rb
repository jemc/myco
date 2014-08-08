
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
  
  class Quest < Node
    attr_accessor :receiver
    attr_accessor :questable
    
    def initialize line, receiver, questable
      @line      = line
      @receiver  = receiver
      @questable = questable
      
      @void_literal = VoidLiteral.new @line
      
      @questable.receiver = Quest::FakeReceiver.new @line
    end
    
    def bytecode g
      pos(g)
      
      ##
      # unless @receiver.respond_to?(@questable.name).false?
      #   execute_statement @questable
      # else
      #   return void
      # end
      
      else_label = g.new_label
      end_label  = g.new_label
      
      @receiver.bytecode g
      g.dup_top # dup the receiver to save it for later
        g.push_literal @questable.name
      g.send :respond_to?, 1
      g.send :false?, 0
      g.goto_if_true else_label
      
      # The duped receiver is still at the top of the stack,
      # and @questable.receiver has been set to an instance of FakeReceiver
      # to let the true receiver pass through instead.
      @questable.bytecode g
      g.goto end_label
      
      else_label.set!
      g.pop # pop the duped receiver - it won't be used after all
      g.push_cpath_top
      g.find_const :Myco
      g.find_const :Void
      
      end_label.set!
    end
    
    def to_sexp
      [:quest, @receiver.to_sexp, @questable.to_sexp]
    end
    
    class FakeReceiver < Node
      def initialize line
        @line = line
      end
      
      def bytecode g
        pos(g)
        # Do nothing here - this would normally be ill-advised,
        # because Nodes are expected to push an item onto the stack,
        # but here we are intentionally not doing so because
        # the real receiver should already at the top of the stack
      end
      
      def to_sexp
        [:qrcvr]
      end
    end
  end
  
  class NullLiteral < NilLiteral
    def to_sexp
      [:null]
    end
  end
  
  # Replace NilLiteral with NullLiteral and let original NilLiteral "disappear"
  NilLiteral = NullLiteral
  
  class VoidLiteral < Node
    def bytecode(g)
      pos(g)
      
      # TODO: create push_void helper to abstract this out (and elsewhere)
      g.push_cpath_top
      g.find_const :Myco
      g.find_const :Void
    end
    
    def to_sexp
      [:void]
    end
  end
  
  
  # Patch the And (and Or) Node bytecode to use .false? to determine falsehood
  # This accomodates treating Void (or any other non-builtin) as falsey
  # TODO: use new branch instruction when it gets added to Rubinius
  class And
    def bytecode(g, use_git=true)
      @left.bytecode(g)
      g.dup
      lbl = g.new_label
      
      g.send :false?, 0
      if use_git
        g.git lbl
      else
        g.gif lbl
      end
      
      g.pop
      @right.bytecode(g)
      lbl.set!
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
    
    def process_quest line, receiver, questable
      Quest.new line, receiver, questable
    end
    
    def process_null line
      NullLiteral.new line
    end
    
    def process_void line
      VoidLiteral.new line
    end
  end
end
