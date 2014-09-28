
class CodeTools::AST::DynamicSymbol
  def to_ruby g
    g.add(':') # prefix with ':', but...
    super # delegate to DynamicString implementation
  end
end
