
class CodeTools::AST::ConstantAssignment
  def to_ruby g
    @constant.to_ruby_assign(g, @value)
  end
end
