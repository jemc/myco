
class CodeTools::AST::Return
  def to_ruby g
    g.add("return ")
    g.add(@value)
  end
end
