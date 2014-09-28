
class CodeTools::AST::ScopedConstant
  def to_ruby g
    g.add(@parent); g.add("::#{@name}")
  end
  
  def to_ruby_assign g, value
    to_ruby(g)
    g.add(" = "); g.add(value)
  end
end
