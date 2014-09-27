
class CodeTools::AST::ToplevelConstant
  def to_ruby g
    g.add("::#{@name}")
  end
end
