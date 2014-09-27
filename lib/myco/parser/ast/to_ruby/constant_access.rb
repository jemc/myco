
class CodeTools::AST::ConstantAccess
  def to_ruby g
    g.add("::Myco.find_constant(#{@name.inspect})")
  end
end
