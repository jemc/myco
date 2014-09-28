
class CodeTools::AST::LocalVariableAccessAmbiguous
  def to_ruby g
    g.add(@name.to_s)
  end
end
