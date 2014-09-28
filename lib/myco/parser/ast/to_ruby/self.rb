
class CodeTools::AST::Self
  def to_ruby g
    g.add("self")
  end
end
