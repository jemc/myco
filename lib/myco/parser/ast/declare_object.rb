
require_relative 'myco_module_scope'


module CodeTools::AST
  
  module ProcessorMethods
    def process_declobj line, types, body
      DeclareObject.new line, types, body
    end
  end
  
  class DeclareObjectScope < MycoModuleScope
    def body_bytecode g
      g.push_scope
      g.send :set_myco_component, 0
      g.pop
      
      @body.bytecode g
    end
  end
  
  class DeclareObject < Node
    attr_accessor :types, :body
    attr_accessor :create
    
    attr_accessor :scope_type
    
    def initialize line, types, body
      @line   = line
      @types  = types
      @body   = body
      
      @create = true
      @scope_type = DeclareObjectScope
    end
    
    def to_sexp
      [:declobj, @types.to_sexp, @body.to_sexp]
    end
    
    def scope_implementation
      @scope_type.new @line, @body
    end
    
    def bytecode g
      pos(g)
      
      # ::Myco::Component.new types, parent, filename
      g.push_cpath_top
      g.find_const :Myco
      g.find_const :Component
        @types.bytecode g
        g.push_scope; g.send :for_method_definition, 0
        g.push_scope; g.send :active_path, 0; g.meta_to_s
        g.push_literal @line
      g.send :new, 4
      
      # The return value of Component.new at the top of the stack
      # will be consumed by @scope.bytecode, so save two copies of it.
      g.dup_top # One for sending :__last__= to
      g.dup_top # One for sending :instance to (or returning, if !@create)
      
      # Compile the inner scope,
      # leaving the last object in the scope at the top of the stack.
      scope_implementation.bytecode g
      
      # component.__last__ = (value left on stack from @scope.bytecode)
      g.send :__last__=, 1
      g.pop
      
      # return (@create ? component.instance : component)
      g.send :instance, 0 if @create
    end
  end
  
end
