
module CodeTools::AST
  # Monkey patch original to use ::Myco to look up constants
  class ConstantAccess
    def bytecode(g)
      pos(g)
      
      g.push_cpath_top
      g.find_const :Myco
        g.push_literal @name
        g.push_scope
      g.send :find_constant, 2
    end
  end
end
