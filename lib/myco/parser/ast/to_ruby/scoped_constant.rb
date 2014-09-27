
class CodeTools::AST::ScopedConstant
  def to_ruby g
    g.add(@parent); g.add("::#{@name}")
  end
end
