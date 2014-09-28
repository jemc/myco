
class CodeTools::AST::FalseLiteral
  def to_ruby g
    g.add("false")
  end
end
