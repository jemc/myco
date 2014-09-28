
class CodeTools::AST::LocalVariableAssignment
  def to_ruby g
    g.add(@name.to_s); g.add(" = "); g.add(value)
  end
end
