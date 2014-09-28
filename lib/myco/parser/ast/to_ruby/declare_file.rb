
class CodeTools::AST::DeclareFile
  def to_ruby g
    g.add(implementation)
  end
end
