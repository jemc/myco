
module CodeTools::AST
  
  # Monkey patch original to use methods of ::Myco to lookup constants
  class ConstantAccess
    def bytecode(g)
      pos(g)
      
      if g.state.op_asgn? # TODO: is this branch unnecessary with Myco AST?
        g.push_cpath_top
        g.find_const :Myco
        g.push_literal @name
        g.push_scope
        g.send :find_constant_for_op_asign_or, 2
      else
        if @top_level
          g.push_cpath_top
          g.find_const @name
        else
          g.push_cpath_top
          g.find_const :Myco
          g.push_literal @name
          g.push_scope
          g.send :find_constant, 2
        end
      end
    end
  end
end
