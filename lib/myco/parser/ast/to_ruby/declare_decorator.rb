
class CodeTools::AST::DeclareDecorator
  def to_ruby g
    g.add("[#{@name.value.inspect}, "); g.add(@arguments); g.add("]")
  end
end
