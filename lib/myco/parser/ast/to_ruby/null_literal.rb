
class CodeTools::AST::NullLiteral
  def to_ruby g
    g.add("nil")
  end
end
