
module CodeTools::AST
  
  class MycoModuleScope < ModuleScope
    def initialize(line, body)
      @line = line
      @name = :MycoModuleScope # TODO: remove/fix
      @body = body
    end
    
    def bytecode(g)
      pos(g)
      
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
  end
  
end
