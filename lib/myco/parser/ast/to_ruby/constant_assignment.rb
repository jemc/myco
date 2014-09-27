
class CodeTools::AST::ConstantAssignment
  def to_ruby g
    @constant.to_ruby_assign(g)
    g.add(" = "); g.add(@value)
  end
end
