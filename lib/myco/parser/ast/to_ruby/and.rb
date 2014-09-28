
class CodeTools::AST::And
  def to_ruby g
    g.add(@left); g.add(" && "); g.add(@right)
  end
end
