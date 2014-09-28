
class CodeTools::AST::ToplevelConstant
  def to_ruby g
    g.add("::#{@name}")
  end
  
  def to_ruby_assign g, value
    to_ruby(g)
    g.add(" = "); g.add(value)
  end
end
