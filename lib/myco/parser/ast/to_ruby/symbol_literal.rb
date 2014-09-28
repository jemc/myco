
class CodeTools::AST::SymbolLiteral
  def to_ruby g
    g.add(@value.inspect)
  end
end
