
class CodeTools::AST::EvalExpression
  def to_ruby g
    g.add(@body)
  end
end
