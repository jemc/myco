
class CodeTools::AST::Invoke
  def to_ruby g
    g.add(implementation)
  end
end
