
class CodeTools::AST::VoidLiteral
  def to_ruby g
    g.add("::Myco::Void")
  end
end
