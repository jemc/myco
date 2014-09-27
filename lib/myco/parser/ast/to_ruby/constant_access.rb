
class CodeTools::AST::ConstantAccess
  def to_ruby g
    g.add("::Myco.find_constant(#{@name.inspect})")
  end
  
  def to_ruby_assign g
    g.add(@name.to_s)
  end
end
