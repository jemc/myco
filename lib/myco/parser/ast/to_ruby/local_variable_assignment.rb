
class CodeTools::AST::LocalVariableAssignment
  def to_ruby g
    g.var_scope_declare_local(@name)
    g.var_scope.variables[@name] = true
    g.add(@name.to_s); g.add(" = "); g.add(value)
  end
end
