
class CodeTools::AST::TrueLiteral
  def to_ruby g
    g.add("true")
  end
end
