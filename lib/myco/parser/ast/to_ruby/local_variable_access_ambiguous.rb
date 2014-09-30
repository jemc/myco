
class CodeTools::AST::LocalVariableAccessAmbiguous
  def to_ruby g
    if g.var_scope_has_local?(@name)
      g.add(@name.to_s)
    else
      g.add("self.")
      g.add(@name.to_s)
    end
  end
end
