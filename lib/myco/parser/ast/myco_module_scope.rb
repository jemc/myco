
module CodeTools::AST
  
  class MycoModuleScope < ModuleScope
    def initialize(line, body)
      @line = line
      @name = :MycoModuleScope # TODO: remove/fix
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
      # Register in the AST as a scope for local variable lookup
      # Right now, this just sets @parent to g.state.scope
      # (Necessary to pass local variables from above to memes below)
      g.state.scope.nest_scope self
      
      attach_and_call g, :__myco_module_init__, true
    end
    
    # TODO: figure out how to keep in sync with ClosedScope#attach_and_call impl
    def attach_and_call(g, arg_name, scoped=false, pass_block=false)
      name = @name || arg_name
      meth = new_generator(g, name)
      
      meth.push_state self
      meth.for_module_body = true
      
      if scoped
        meth.push_self
        meth.add_scope
      end
      
      meth.state.push_name name
      
      body_bytecode meth # (@body.bytecode meth) in original implementation
      
      meth.state.pop_name
      
      meth.ret
      meth.close
      
      meth.local_count = local_count
      meth.local_names = local_names
      
      meth.pop_state
      
      g.create_block meth
      g.swap
      g.push_scope
      g.push_true
      g.send :call_under, 3
      
      return meth
    end
    
    def body_bytecode g
      @body.bytecode g
    end
    
    include CodeTools::Compiler::LocalVariables
    
    # Become the AST scope parent of the given AST scope Node .
    # This is only for the benefit of LocalVariableAccessAmbiguous
    # being able to call search_local, and has nothing to do with
    # the scope referenced by g.push_scope or g.add_scope
    def nest_scope scope
      scope.parent = self
    end
    
    attr_accessor :parent
    
    # This is an abbreviated form of Iter#search_local
    # because no locals can be assigned within the MycoModuleScope
    def search_local name
      if reference = @parent.search_local(name)
        reference.depth += 1
        reference
      end
    end
  end
  
end
