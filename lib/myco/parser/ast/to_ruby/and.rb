
class CodeTools::AST::And
  def to_ruby g
    g.add('::Myco.and('); g.add(@left); g.add(') {'); g.add(@right); g.add('}')
  end
end
