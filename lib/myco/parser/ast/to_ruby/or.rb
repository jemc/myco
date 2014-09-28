
class CodeTools::AST::Or
  def to_ruby g
    g.add('::Myco.or('); g.add(@left); g.add(') {'); g.add(@right); g.add('}')
  end
end
