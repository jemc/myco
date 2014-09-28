
class CodeTools::AST::Iter
  def to_ruby g
    g.add(" "); g.add(@arguments); g.add(" "); g.add(@body)
  end
end
