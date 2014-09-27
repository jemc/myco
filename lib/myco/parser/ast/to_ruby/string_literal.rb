
class CodeTools::AST::StringLiteral
  def to_ruby g
    g.add(@string.inspect)
  end
end
